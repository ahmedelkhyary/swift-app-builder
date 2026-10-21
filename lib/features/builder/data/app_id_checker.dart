import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../firebase.dart' as fb;

/// The check could not be completed (offline, backend unreachable, ...).
class AppIdCheckException implements Exception {
  const AppIdCheckException([this.detail]);
  final String? detail;
  @override
  String toString() => 'AppIdCheckException(${detail ?? ''})';
}

/// Tells whether an App ID can still be used.
///
/// Implementations only ever answer yes or no: the requests of other clients
/// are never readable from the browser.
abstract class AppIdChecker {
  /// [appId] must already be normalized and well-formed.
  Future<bool> isAvailable(String appId);
}

/// Looks up the marker document `app_ids/{appId}`. These documents hold no
/// client data (only `createdAt`), so the security rules let anyone `get` one
/// by id but never list them; they are created together with the request.
class FirestoreAppIdChecker implements AppIdChecker {
  static const collection = 'app_ids';

  @override
  Future<bool> isAvailable(String appId) async {
    try {
      await fb.ensureFirebase();
      final snap = await fb.firestore.collection(collection).doc(appId).get();
      return !snap.exists;
    } on fb.FirebaseNotConfigured catch (e) {
      throw AppIdCheckException('$e');
    } on FirebaseException catch (e) {
      throw AppIdCheckException(e.code);
    } catch (e) {
      throw AppIdCheckException('$e');
    }
  }
}

/// In-memory checker (tests, offline development).
class InMemoryAppIdChecker implements AppIdChecker {
  InMemoryAppIdChecker({Set<String>? taken, this.failing = false})
    : taken = {...?taken};

  final Set<String> taken;

  /// Simulates a network failure.
  bool failing;
  final calls = <String>[];

  @override
  Future<bool> isAvailable(String appId) async {
    calls.add(appId);
    if (failing) throw const AppIdCheckException('offline');
    return !taken.contains(appId);
  }
}
