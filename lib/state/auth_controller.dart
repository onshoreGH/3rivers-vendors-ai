import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../core/api/auth_api.dart';
import '../core/api/three_rivers_api.dart';
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
  final ThreeRiversApi Function() _api;

  AuthController({
    required AuthApi authApi,
    required SecureTokenStorage storage,
    required ThreeRiversApi Function() api,
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
    final session = await _authApi.login(username: username, password: password);
    await _apply(session);
  }

  Future<bool> _tryRefresh() async {
    final refresh = _refreshToken;
    if (refresh == null) return false;
    try {
      await _apply(await _authApi.refresh(refresh), silent: true);
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<void> _apply(Session session, {bool silent = false}) async {
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
