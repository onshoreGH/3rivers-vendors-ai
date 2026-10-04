import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../core/api/auth_api.dart';
import '../core/api/vendors_api.dart';
import '../core/models/auth_session.dart';
import '../core/models/user_profile.dart';
import '../core/storage/secure_token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-root auth state.
///  1. Restores a session from secure storage on launch (silent refresh if
///     the access token is expired and a refresh token exists).
///  2. Drives username/password login (Keycloak, via the 3Rivers API).
///  3. Single place ApiClient's 401 interceptor calls into.
///  4. Holds the loaded [UserProfile].
class AuthController extends ChangeNotifier {
  final AuthApi _authApi;
  final SecureTokenStorage _storage;
  final VendorsApi Function() _api;

  AuthController({
    required AuthApi authApi,
    required SecureTokenStorage storage,
    required VendorsApi Function() api,
  })  : _authApi = authApi,
        _storage = storage,
        _api = api;

  AuthStatus status = AuthStatus.unknown;
  UserProfile? profile;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  Future<String?> currentToken() async {
    if (_accessToken == null) return null;
    if (_expiresAt != null &&
        _expiresAt!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      await _tryRefresh();
    }
    return _accessToken;
  }

  Future<void> restoreSession() async {
    _accessToken = await _storage.readAccessToken();
    _refreshToken = await _storage.readRefreshToken();
    _expiresAt = await _storage.readExpiresAt();

    if (_accessToken == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final expired = _expiresAt != null && _expiresAt!.isBefore(DateTime.now());
    if (expired && !await _tryRefresh()) {
      await logout();
      return;
    }

    status = AuthStatus.authenticated;
    notifyListeners();
    unawaited(_loadProfile());
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final session = await _authApi.login(
      login: username,
      password: password,
      deviceName: _deviceName,
    );
    await _apply(session);
  }

  /// Shown to the user in the portal's list of active tokens, so it names the
  /// device rather than the app. Sanctum requires it on every login and
  /// rejects the request with 422 if it is missing.
  static const _deviceName = 'Onshore 3Rivers Vendors (mobile)';

  /// Sanctum issues long-lived personal access tokens and exposes NO refresh
  /// endpoint, so there is nothing to rotate -- the previous Keycloak
  /// implementation called /auth/refresh, which does not exist on this API.
  /// A token stops working only when it is revoked server-side or by logout,
  /// and the login response carries no expires_in, so [_expiresAt] stays null
  /// and the expiry branch never fires. Kept explicit rather than deleted so
  /// the absence reads as a decision rather than an oversight.
  Future<bool> _tryRefresh() async => false;

  /// `silent` is gone with the refresh path: it existed so a background token
  /// rotation would not flash the UI, and Sanctum has no rotation.
  Future<void> _apply(Session session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken ?? _refreshToken;
    _expiresAt = session.expiresAt;
    profile = session.user ?? profile;
    status = AuthStatus.authenticated;
    await _storage.save(
      accessToken: session.accessToken,
      refreshToken: _refreshToken,
      expiresAt: _expiresAt,
    );
    notifyListeners();
    if (session.user == null) unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    try {
      profile = await _api().me();
      notifyListeners();
    } on ApiException {
      // Non-fatal.
    }
  }

  Future<void> refreshProfile() => _loadProfile();

  void forceLogout() {
    if (status != AuthStatus.authenticated) return;
    _clear();
    notifyListeners();
  }

  Future<void> logout() async {
    _clear();
    await _storage.clear();
    notifyListeners();
  }

  void _clear() {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    profile = null;
    status = AuthStatus.unauthenticated;
    unawaited(_storage.clear());
  }
}
