import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_options.dart';

/// Optional overrides of the generated Firebase settings, read from
/// compile-time environment values (`--dart-define-from-file=.env`, see
/// `.env.example`). When none are given, `firebase_options.dart` (created by
/// `flutterfire configure`) is used.
class FirebaseEnv {
  const FirebaseEnv._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');

  /// True when every required override was provided.
  static bool get isOverridden =>
      apiKey.isNotEmpty &&
      projectId.isNotEmpty &&
      storageBucket.isNotEmpty &&
      appId.isNotEmpty;

  static FirebaseOptions get options => const FirebaseOptions(
    apiKey: apiKey,
    authDomain: authDomain,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: appId,
  );
}

/// Thrown when no Firebase settings are available for this platform.
class FirebaseNotConfigured implements Exception {
  const FirebaseNotConfigured();
  @override
  String toString() => 'Firebase is not configured for this platform';
}

/// The single place where Firebase is initialized (lazily, once).
Future<void> ensureFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  final FirebaseOptions options;
  if (FirebaseEnv.isOverridden) {
    options = FirebaseEnv.options;
  } else {
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } on UnsupportedError {
      throw const FirebaseNotConfigured();
    }
  }
  await Firebase.initializeApp(options: options);
}

/// Firestore instance; call [ensureFirebase] first.
FirebaseFirestore get firestore => FirebaseFirestore.instance;

/// Cloud Storage instance; call [ensureFirebase] first.
FirebaseStorage get storage => FirebaseStorage.instance;
