import 'json.dart';
import 'user_profile.dart';

/// Result of POST /api/v1/auth/login or /auth/refresh — a Keycloak-issued
/// session, proxied by the 3Rivers API.
class Session {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final UserProfile? user;

  const Session({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.user,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'];
    return Session(
      accessToken: asString(json['access_token']),
      refreshToken: json['refresh_token'] as String?,
      expiresAt: expiresIn == null
          ? null
          : DateTime.now().add(Duration(seconds: asInt(expiresIn))),
      user: json['user'] is Map<String, dynamic>
          ? UserProfile.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
