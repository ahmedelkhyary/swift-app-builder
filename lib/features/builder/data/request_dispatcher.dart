import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../firebase_options.dart';

/// The Cloud Functions region the pipeline dispatch functions are deployed
/// to (see `functions/src/index.ts`). Independent of the Firestore
/// database's own region.
const _dispatchRegion = 'us-central1';

/// Asks the backend to dispatch the Azure DevOps pipeline for a request right
/// away, instead of waiting for its periodic sweep. Best-effort: a request
/// that already exists and is `pending` will still be picked up by that sweep
/// even if this never reaches the function.
abstract class RequestDispatcher {
  Future<void> dispatch(String requestId);

  /// Asks the backend to queue the "request received" confirmation email for
  /// a just-created request. Best-effort, like [dispatch]: the Cloud Function
  /// is idempotent (keyed on `notification.pipelineRunId`), so this is safe
  /// to skip or retry.
  Future<void> notifyCreated(String requestId);
}

class HttpRequestDispatcher implements RequestDispatcher {
  HttpRequestDispatcher({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  @override
  Future<void> dispatch(String requestId) => _post('/dispatchAppRequest', requestId);

  @override
  Future<void> notifyCreated(String requestId) =>
      _post('/triggerConfirmationEmail', requestId);

  Future<void> _post(String path, String requestId) async {
    final projectId = DefaultFirebaseOptions.web.projectId;
    final url = Uri.https('$_dispatchRegion-$projectId.cloudfunctions.net', path);
    try {
      await _client
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'requestId': requestId}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Swallowed: the scheduled sweep (dispatch) or a manual resend
      // (notify) covers a dropped call.
    }
  }
}
