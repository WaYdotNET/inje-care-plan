import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../core/database/app_database.dart';

/// Rappresentazione locale dell'utente (senza Firebase)
class LocalUser {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  LocalUser({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  factory LocalUser.fromGoogleSignIn(GoogleSignInAccount account) {
    return LocalUser(
      id: account.id,
      displayName: account.displayName,
      email: account.email,
      photoUrl: account.photoUrl,
    );
  }
}

/// Authentication repository - versione offline-first senza Firebase
class AuthRepository {
  AuthRepository({
    GoogleSignIn? googleSignIn,
    LocalAuthentication? localAuth,
    AppDatabase? database,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]),
        _localAuth = localAuth ?? LocalAuthentication(),
        _database = database;

  final GoogleSignIn _googleSignIn;
  final LocalAuthentication _localAuth;
  final AppDatabase? _database;

  LocalUser? _currentUser;

  /// Get current user (locale)
  LocalUser? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Initialize auth state from stored data
  Future<void> initialize(AppDatabase db) async {
    // Prova a recuperare il profilo salvato
    final profile = await db.getUserProfile();
    if (profile != null && profile.email.isNotEmpty) {
      _currentUser = LocalUser(
        id: profile.id.toString(),
        displayName: profile.displayName,
        email: profile.email,
        photoUrl: profile.photoUrl,
      );
    }

    // Prova silent sign-in per rinnovare token Google
    final googleUser = await _googleSignIn.signInSilently();
    if (googleUser != null && _currentUser == null) {
      _currentUser = LocalUser.fromGoogleSignIn(googleUser);
      await _saveUserProfile(db, googleUser);
    }
  }

  /// Sign in with Google (solo per Google Drive access)
  Future<LocalUser?> signInWithGoogle(AppDatabase db) async {
    try {
      // Trigger the authentication flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      _currentUser = LocalUser.fromGoogleSignIn(googleUser);
      await _saveUserProfile(db, googleUser);

      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Save user profile to local database
  Future<void> _saveUserProfile(
      AppDatabase db, GoogleSignInAccount googleUser) async {
    final existingProfile = await db.getUserProfile();

    if (existingProfile != null) {
      await db.updateUserProfile(UserProfilesCompanion(
        id: Value(existingProfile.id),
        displayName: Value(googleUser.displayName ?? ''),
        email: Value(googleUser.email),
        photoUrl: Value(googleUser.photoUrl ?? ''),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      await db.insertUserProfile(UserProfilesCompanion.insert(
        displayName: Value(googleUser.displayName ?? ''),
        email: Value(googleUser.email),
        photoUrl: Value(googleUser.photoUrl ?? ''),
      ));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Sblocca InjeCare Plan',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric authentication (saved in local DB)
  Future<void> setBiometricEnabled(AppDatabase db, bool enabled) async {
    final profile = await db.getUserProfile();
    if (profile == null) return;

    await db.updateUserProfile(UserProfilesCompanion(
      id: Value(profile.id),
      biometricEnabled: Value(enabled),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Check if biometric is enabled for user
  Future<bool> isBiometricEnabled(AppDatabase db) async {
    final profile = await db.getUserProfile();
    return profile?.biometricEnabled ?? false;
  }

  /// Get Google account for API access (Drive, Calendar)
  GoogleSignInAccount? get googleAccount => _googleSignIn.currentUser;
}
