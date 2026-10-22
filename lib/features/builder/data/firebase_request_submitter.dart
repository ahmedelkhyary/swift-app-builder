import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../firebase.dart' as fb;
import '../domain/asset.dart';
import '../domain/draft.dart';
import '../domain/request_document.dart';
import '../domain/validators.dart';
import 'app_id_checker.dart';
import 'request_dispatcher.dart';
import 'request_submitter.dart';

/// Writes requests to Firestore (`app_requests/{appId}`) and uploads the
/// images to Storage (`app_requests/{appId}/…`).
///
/// Image files get a unique name per submission, so a request is never
/// overwritten silently, not even its images.
class FirebaseRequestSubmitter implements RequestSubmitter {
  FirebaseRequestSubmitter({RequestDispatcher? dispatcher})
    : _dispatcher = dispatcher ?? HttpRequestDispatcher();

  static const collection = 'app_requests';

  final RequestDispatcher _dispatcher;

  @override
  Future<SubmitResult> submit(AppConfigDraft draft) async {
    final appId = normalizeAppId(draft.appId);
    if (!Validators.appIdRegex.hasMatch(appId)) {
      throw const SubmitException(SubmitErrorKind.invalidAppId);
    }
    try {
      await fb.ensureFirebase();
    } on fb.FirebaseNotConfigured {
      throw const SubmitException(SubmitErrorKind.notConfigured);
    } on FirebaseException catch (e) {
      throw SubmitException(_kind(e), e.message);
    }

    final db = fb.firestore;
    final idRef = db.collection(FirestoreAppIdChecker.collection).doc(appId);
    final requestRef = db.collection(collection).doc(appId);
    try {
      // Fast path: do not upload anything for an ID that is already used.
      if ((await idRef.get()).exists) return SubmitResult.taken;

      final stamp = DateTime.now().millisecondsSinceEpoch;
      final logoUrl = await _upload(appId, 'logo', stamp, draft.logo!);
      final iconUrl = await _upload(appId, 'app_icon', stamp, draft.appIcon!);
      final splash = draft.splashLogo;
      final splashUrl = splash == null
          ? null
          : await _upload(appId, 'splash_logo', stamp, splash);
      final fields = requestFields(
        draft.copyWith(appId: appId),
        logoUrl: logoUrl,
        appIconUrl: iconUrl,
        splashLogoUrl: splashUrl,
      );

      // The final check and the writes are one transaction, so two clients
      // choosing the same ID at the same time cannot both succeed. The rules
      // only allow creating (never updating) both documents.
      final result = await db.runTransaction<SubmitResult>((tx) async {
        if ((await tx.get(idRef)).exists) return SubmitResult.taken;
        tx.set(idRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.set(requestRef, {
          ...fields,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return SubmitResult.created;
      });
      // Nudges the backend to dispatch the build pipeline now rather than
      // wait for its periodic sweep; never fails the submission.
      if (result == SubmitResult.created) await _dispatcher.dispatch(appId);
      return result;
    } on FirebaseException catch (e) {
      // Losing the race can also surface as a rules rejection of the create.
      // A request document that exists without its marker (created before
      // markers existed) also rejects the create: that ID is not free either.
      if (e.code == 'already-exists' || e.code == 'permission-denied') {
        return SubmitResult.taken;
      }
      throw SubmitException(_kind(e), e.message);
    }
  }

  Future<String> _upload(
    String appId,
    String base,
    int stamp,
    PickedAsset asset,
  ) async {
    // Already in our storage: use its public URL as it is.
    if (asset.isRemote) return asset.sourceUrl!;
    final ext = asset.extension;
    final object = fb.storage.ref('$collection/$appId/${base}_$stamp.$ext');
    await object.putData(
      Uint8List.fromList(asset.bytes),
      SettableMetadata(
        contentType: asset.isSvg ? 'image/svg+xml' : 'image/png',
      ),
    );
    return object.getDownloadURL();
  }

  SubmitErrorKind _kind(FirebaseException e) => switch (e.code) {
    'permission-denied' || 'unauthorized' => SubmitErrorKind.permission,
    'unavailable' ||
    'network-request-failed' ||
    'retry-limit-exceeded' ||
    'deadline-exceeded' => SubmitErrorKind.network,
    _ => SubmitErrorKind.unknown,
  };
}
