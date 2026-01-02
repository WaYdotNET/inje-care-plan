import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase service for app initialization and configuration
class FirebaseService {
  FirebaseService._();

  static final instance = FirebaseService._();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Initialize Firestore with offline persistence
  Future<void> initializeFirestore() async {
    // Enable offline persistence (enabled by default on mobile)
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Get current user ID
  String? get currentUserId => auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => auth.currentUser != null;

  /// Get user document reference
  DocumentReference<Map<String, dynamic>> userDoc(String userId) {
    return firestore.collection('users').doc(userId);
  }

  /// Get user's injections collection
  CollectionReference<Map<String, dynamic>> injectionsCollection(String userId) {
    return userDoc(userId).collection('injections');
  }

  /// Get user's body zones collection
  CollectionReference<Map<String, dynamic>> bodyZonesCollection(String userId) {
    return userDoc(userId).collection('bodyZones');
  }

  /// Get user's blacklisted points collection
  CollectionReference<Map<String, dynamic>> blacklistedPointsCollection(String userId) {
    return userDoc(userId).collection('blacklistedPoints');
  }

  /// Get user's therapy plan document
  DocumentReference<Map<String, dynamic>> therapyPlanDoc(String userId) {
    return userDoc(userId).collection('settings').doc('therapyPlan');
  }
}
