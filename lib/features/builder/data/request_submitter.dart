import '../domain/draft.dart';

/// Outcome of submitting a request.
enum SubmitResult {
  /// The request was created.
  created,

  /// The request was created but its payment secret keys could not be stored
  /// (the backend was unreachable). The client has to be asked for them again.
  createdSecretsPending,

  /// The App ID is already used (maybe just now, by someone else). Nothing was
  /// written and an existing request is never overwritten.
  taken,
}

/// Why a submission failed.
enum SubmitErrorKind {
  notConfigured,
  invalidAppId,
  permission,
  network,
  unknown,
}

class SubmitException implements Exception {
  const SubmitException(this.kind, [this.detail]);
  final SubmitErrorKind kind;
  final String? detail;

  @override
  String toString() =>
      'SubmitException($kind${detail == null ? '' : ': $detail'})';
}

/// Sends a finished wizard to the backend as an "app request".
abstract class RequestSubmitter {
  /// Creates the request under its App ID, only if that ID is still free.
  Future<SubmitResult> submit(AppConfigDraft draft);
}
