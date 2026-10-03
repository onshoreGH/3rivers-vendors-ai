import 'package:flutter/material.dart';

/// Per-vertical branding + endpoints. 3Rivers here; the shared app shell
/// (auth, nav, AsyncView, theme) is vertical-neutral.
abstract class AppConfig {
  const AppConfig();

  /// Marketplace name — must stay close to the App Store Connect "Name"
  /// (Apple 2.3.8).
  String get appName;

  /// Reverse-DNS id, fixed to the existing ASC record.
  String get bundleId;

  String get supportEmail;
  Uri get privacyPolicyUrl;
  Uri get termsUrl;

  String get privacyAssetPath => 'assets/legal/privacy.md';
  String get termsAssetPath => 'assets/legal/terms.md';

  Color get seedColor;
  String? get logoAssetPath;
}

class ThreeRiversConfig extends AppConfig {
  const ThreeRiversConfig();

  @override
  String get appName => 'Onshore 3Rivers AI';

  @override
  String get bundleId => 'ai.onshoretech.onshore-3rivers-ai';

  @override
  String get supportEmail => 'support@onshoretech.ai';

  @override
  Uri get privacyPolicyUrl => Uri.parse('https://3rivers.onshoretech.ai/privacy');

  @override
  Uri get termsUrl => Uri.parse('https://3rivers.onshoretech.ai/terms');

  @override
  Color get seedColor => const Color(0xFF1FA463); // 3Rivers green

  @override
  String? get logoAssetPath => 'assets/branding/icon_source.png';
}
