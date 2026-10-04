/// App-wide config. The API base is the 3Rivers portal root — the mobile
/// API lives at `/api/v1/*` (JWT bearer, NOT behind the browser
/// oauth2-proxy). Auth is at `/api/v1/auth/*`.
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://3rivers-v.onshoretech.ai',
  );

  static const bool friendlyNetworkErrors = bool.fromEnvironment(
    'FRIENDLY_NETWORK_ERRORS',
    defaultValue: true,
  );
}
