import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/api/auth_api.dart';
import 'core/api/vendors_api.dart';
import 'core/config/app_config.dart';
import 'core/storage/local_prefs.dart';
import 'core/storage/secure_token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/home_shell.dart';
import 'state/auth_controller.dart';

class OnshoreThreeRiversApp extends StatefulWidget {
  const OnshoreThreeRiversApp({super.key});

  @override
  State<OnshoreThreeRiversApp> createState() => _OnshoreThreeRiversAppState();
}

class _OnshoreThreeRiversAppState extends State<OnshoreThreeRiversApp> {
  late final SecureTokenStorage _storage;
  late final ApiClient _apiClient;
  late final AuthApi _authApi;
  late final VendorsApi _api;
  late final AuthController _auth;
  late final LocalPrefs _prefs;

  @override
  void initState() {
    super.initState();
    _storage = SecureTokenStorage();
    _prefs = LocalPrefs();

    _apiClient = ApiClient(
      tokenProvider: () => _auth.currentToken(),
      onUnauthorized: () => _auth.forceLogout(),
    );
    _authApi = AuthApi(_apiClient);
    _api = VendorsApi(_apiClient);
    _auth = AuthController(
      authApi: _authApi,
      storage: _storage,
      api: () => _api,
    )..restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    const config = ThreeRiversConfig();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        Provider<VendorsApi>.value(value: _api),
        Provider<LocalPrefs>.value(value: _prefs),
        Provider<AppConfig>.value(value: config),
      ],
      child: MaterialApp(
        title: config.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Consumer<AuthController>(
          builder: (context, auth, _) => switch (auth.status) {
            AuthStatus.unknown => const _Splash(),
            AuthStatus.authenticated => const HomeShell(),
            AuthStatus.unauthenticated => const LoginScreen(),
          },
        ),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
