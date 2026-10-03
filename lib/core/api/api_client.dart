import 'package:dio/dio.dart';

import '../config/env.dart';
import 'api_exception.dart';

/// Paths that never carry a bearer token -- the Keycloak-proxy auth
/// endpoints. Everything else under /api/v1/* carries the Keycloak
/// access token.
const _publicPaths = {
  '/api/v1/auth/login',
  '/api/v1/auth/refresh',
};

/// Single Dio instance for the whole app. Token/401 callbacks are injected
/// (rather than depending on AuthController directly) to avoid a circular
/// dependency: app.dart constructs this first, then wires the real
/// callbacks once AuthController exists.
class ApiClient {
  final Dio dio;

  ApiClient({
    required Future<String?> Function() tokenProvider,
    required void Function() onUnauthorized,
  }) : dio = Dio(BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_publicPaths.contains(options.path)) {
          final token = await tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final is401 = error.response?.statusCode == 401;
        if (is401 && !_publicPaths.contains(error.requestOptions.path)) {
          onUnauthorized();
        }
        handler.next(error);
      },
    ));
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send<T>(path, 'GET', query: query);

  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? query}) =>
      _send<T>(path, 'POST', body: body, query: query);

  Future<T> _send<T>(
    String path,
    String method, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await dio.request<T>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );
      return res.data as T;
    } on DioException catch (e) {
      throw _translate(e);
    }
  }

  ApiException _translate(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    String? serverMessage;
    String? serverCode;
    if (data is Map) {
      // Accept {error:{code,message}}, {message}, or FastAPI's
      // {detail: "..."} / {detail: {code, message}}.
      final err = data['error'] ?? data['detail'];
      if (err is Map) {
        serverMessage = err['message'] as String?;
        serverCode = err['code'] as String?;
      } else if (err is String) {
        serverMessage = err;
      } else if (data['message'] is String) {
        serverMessage = data['message'] as String;
      }
    }

    final noResponse = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown && e.response == null;

    if (noResponse) {
      return const ApiException(
        null,
        "Can't reach 3Rivers right now. Check your connection and try again.",
        isNetwork: true,
      );
    }

    return ApiException(
      status,
      serverMessage ?? _defaultFor(status),
      code: serverCode,
    );
  }

  String _defaultFor(int? status) => switch (status) {
        401 => 'Your session has expired. Please sign in again.',
        403 => "You don't have access to that.",
        404 => 'Not found.',
        final int s when s >= 500 =>
          'The server ran into a problem. Please try again shortly.',
        _ => 'Something went wrong. Please try again.',
      };
}
