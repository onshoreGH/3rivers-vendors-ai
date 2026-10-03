/// Typed API failure. Carries the HTTP status so screens can distinguish
/// "not signed in" (401) from "not found" (404) from "server down" (null /
/// 5xx) and message each appropriately. [isNetwork] is true when the
/// request never got a response at all (no connectivity, DNS, timeout).
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? code;
  final bool isNetwork;

  const ApiException(
    this.statusCode,
    this.message, {
    this.code,
    this.isNetwork = false,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
