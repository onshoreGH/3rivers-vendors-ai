import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-secret per-device preferences. Nothing session- or
/// auth-related -- that all lives in SecureTokenStorage.
class LocalPrefs {
  static const _themeModeKey = 'theme_mode'; // system | light | dark
  static const _notificationsKey = 'notifications_enabled';

  Future<String> getThemeMode() async =>
      (await SharedPreferences.getInstance()).getString(_themeModeKey) ??
      'system';

  Future<void> setThemeMode(String value) async =>
      (await SharedPreferences.getInstance()).setString(_themeModeKey, value);

  Future<bool> getNotificationsEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_notificationsKey) ?? true;

  Future<void> setNotificationsEnabled(bool value) async =>
      (await SharedPreferences.getInstance())
          .setBool(_notificationsKey, value);
}
