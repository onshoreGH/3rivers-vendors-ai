import '../models/auth_session.dart';
import 'api_client.dart';

/// POST /api/auth/* — the Vendors portal's own Laravel Sanctum auth.
///
/// This is deliberately NOT the 3Rivers shape. Three differences matter and
/// each one is a silent failure if you assume the sibling app's contract:
///
///  * the identity field is `login`, not `username` or `email`;
///  * `device_name` is REQUIRED — Laravel validates it and returns 422
///    without it, which reads as a credential failure but is not one;
///  * Sanctum issues a long-lived personal access token and has no refresh
///    endpoint at all, so there is nothing to rotate. The token is revoked
///    server-side by POST /api/auth/logout.
///
/// Routes live behind nginx `location ^~ /api/`, which is exempt from the
/// oauth2-proxy SSO gate that fronts the browser portal; without that
/// exemption every call here answers 302 to Keycloak.
class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  /// [deviceName] is surfaced to the user in the portal's token list, so it
  /// should name the device rather than the app.
  Future<Session> login({
    required String login,
    required String password,
    required String deviceName,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/api/auth/login',
      body: {
        'login': login,
        'password': password,
        'device_name': deviceName,
      },
    );
    return Session.fromJson(json);
  }

  /// Revokes the current personal access token server-side. Best-effort: the
  /// caller clears local storage regardless, so a failure here cannot strand
  /// someone in a signed-in state on the device.
  Future<void> logout() async {
    await _client.post<Map<String, dynamic>>('/api/auth/logout');
  }
}
