import 'package:drift/drift.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/database/app_database.dart';

/// Rappresentazione locale dell'utente
class LocalUser {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  const LocalUser({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
  });
}

/// Authentication repository - versione offline-first senza Google
class AuthRepository {
  AuthRepository({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;
  LocalUser? _currentUser;

  /// Get current user (locale)
  LocalUser? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Initialize auth state from stored data
  Future<void> initialize(AppDatabase db) async {
    final profile = await db.getUserProfile();
    if (profile != null) {
      _currentUser = LocalUser(
        id: profile.id.toString(),
        displayName: profile.displayName,
        email: profile.email,
        photoUrl: profile.photoUrl,
      );
    }
  }

  /// Salva profilo utente locale
  Future<LocalUser> saveLocalProfile(
    AppDatabase db, {
    required String displayName,
    String? email,
  }) async {
    final existingProfile = await db.getUserProfile();

    if (existingProfile != null) {
      await db.updateUserProfile(
        UserProfilesCompanion(
          id: Value(existingProfile.id),
          displayName: Value(displayName),
          email: Value(email ?? ''),
          updatedAt: Value(DateTime.now()),
        ),
      );
      _currentUser = LocalUser(
        id: existingProfile.id.toString(),
        displayName: displayName,
        email: email,
      );
    } else {
      final id = await db.insertUserProfile(
        UserProfilesCompanion.insert(
          displayName: Value(displayName),
          email: Value(email ?? ''),
        ),
      );
      _currentUser = LocalUser(
        id: id.toString(),
        displayName: displayName,
        email: email,
      );
    }

    return _currentUser!;
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
      );
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric authentication
  Future<void> setBiometricEnabled(AppDatabase db, bool enabled) async {
    final profile = await db.getUserProfile();
    if (profile == null) return;

    await db.updateUserProfile(
      UserProfilesCompanion(
        id: Value(profile.id),
        biometricEnabled: Value(enabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled(AppDatabase db) async {
    final profile = await db.getUserProfile();
    return profile?.biometricEnabled ?? false;
  }
}
