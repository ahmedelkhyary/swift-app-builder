import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../../firebase_options.dart';
import '../domain/payments.dart';

/// Region of the payment Cloud Functions (see `functions/src/index.ts`).
const _functionsRegion = 'us-central1';

Uri _functionUri(String path) => Uri.https(
  '$_functionsRegion-${DefaultFirebaseOptions.web.projectId}.cloudfunctions.net',
  path,
);

/// Result of a connection test. [code] is one of [ok], [invalidCredentials],
/// [notImplemented] (the gateway's check is not built yet: never a success),
/// [unreachable] or [error]; [detail] is the gateway's own message, if any.
class GatewayTestResult {
  const GatewayTestResult(this.code, [this.detail]);

  static const ok = 'ok';
  static const invalidCredentials = 'invalid-credentials';
  static const notImplemented = 'not-implemented';
  static const unreachable = 'unreachable';
  static const error = 'error';

  final String code;
  final String? detail;

  bool get isOk => code == ok;
}

/// Calls `POST /payment-gateways/:id/test` on the backend.
abstract class PaymentGatewayTester {
  /// [credentials] are the values of the gateway's fields for [env] (secrets
  /// included): they go to our backend over HTTPS and nowhere else.
  Future<GatewayTestResult> test(
    String gatewayId,
    PaymentEnv env,
    Map<String, String> credentials,
  );
}

class HttpPaymentGatewayTester implements PaymentGatewayTester {
  HttpPaymentGatewayTester({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;

  @override
  Future<GatewayTestResult> test(
    String gatewayId,
    PaymentEnv env,
    Map<String, String> credentials,
  ) async {
    final url = _functionUri(
      '/paymentGateways/payment-gateways/$gatewayId/test',
    );
    try {
      final res = await _client
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'environment': env.name,
              'credentials': credentials,
            }),
          )
          .timeout(const Duration(seconds: 25));
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map && body['code'] is String) {
        return GatewayTestResult(
          body['code'] as String,
          body['message'] as String?,
        );
      }
    } catch (_) {
      // Falls through to the generic failure below.
    }
    return const GatewayTestResult(GatewayTestResult.unreachable);
  }
}

/// Stores the secret keys of a submitted request on the backend (encrypted,
/// never in the request document or the config).
abstract class PaymentSecretsSaver {
  /// Returns true when every secret was stored.
  Future<bool> save(String appId, String token, PaymentsDraft payments);
}

class HttpPaymentSecretsSaver implements PaymentSecretsSaver {
  HttpPaymentSecretsSaver({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;

  @override
  Future<bool> save(String appId, String token, PaymentsDraft payments) async {
    final url = _functionUri('/savePaymentSecrets');
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final res = await _client
            .post(
              url,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'appId': appId,
                'token': token,
                'secrets': payments.secrets(),
              }),
            )
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) return true;
        // A rejected request will not be accepted on a retry.
        if (res.statusCode >= 400 && res.statusCode < 500) return false;
      } catch (_) {
        // Network problem: retried below.
      }
      await Future<void>.delayed(Duration(seconds: 1 << attempt));
    }
    return false;
  }
}

/// One-time token that authorizes the secrets call for one submission. Only
/// its hash is stored in the request document, which the browser cannot read
/// back, so nobody else can plant keys for someone else's app.
class SecretsToken {
  SecretsToken._(this.value, this.hash);

  factory SecretsToken.generate([Random? random]) {
    final r = random ?? Random.secure();
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    final value = base64Url.encode(bytes).replaceAll('=', '');
    return SecretsToken._(value, hashOf(value));
  }

  final String value;

  /// Hex SHA-256 of [value].
  final String hash;

  static String hashOf(String value) =>
      sha256.convert(utf8.encode(value)).toString();
}
