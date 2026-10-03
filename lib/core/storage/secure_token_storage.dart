import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the session issued by /auth/verify-otp (or /auth/login when a
/// tenant doesn't require OTP). Holds the access token, the optional
/// refresh token, and the access token's expiry so the app can refresh
/// proactively rather than waiting for a 401.
class SecureTokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _expiresKey = 'access_expires_at';

  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> save({
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
    if (expiresAt != null) {
      await _storage.write(
          key: _expiresKey, value: expiresAt.toIso8601String());
    }
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<DateTime?> readExpiresAt() async {
    final raw = await _storage.read(key: _expiresKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiresKey);
  }
}
