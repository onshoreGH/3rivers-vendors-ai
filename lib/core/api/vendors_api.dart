import '../models/user_profile.dart';
import '../models/vendor_models.dart';
import 'api_client.dart';

/// Vendor-facing calls against the 3Rivers Vendors Laravel portal.
///
/// Two differences from the sibling 3Rivers app, both of which fail quietly if
/// assumed away:
///
///  * paths are `/api/*`, NOT `/api/v1/*`;
///  * list endpoints wrap rows in `data` with a sibling `meta`, rather than
///    the `items` key the staff API uses.
///
/// Every request must send `Accept: application/json`. Without it Laravel's
/// Authenticate middleware answers 302 to a login page instead of 401/422,
/// so failures surface as HTML redirects rather than errors. ApiClient sets
/// this globally; it is restated here because it is not optional.
class VendorsApi {
  final ApiClient _client;
  VendorsApi(this._client);

  List<T> _data<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) f,
  ) =>
      (json['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(f)
          .toList(growable: false);

  Future<UserProfile> me() async =>
      UserProfile.fromJson(await _client.get<Map<String, dynamic>>('/api/me'));

  Future<FinancialSummary> financialSummary() async {
    final json =
        await _client.get<Map<String, dynamic>>('/api/financials/summary');
    return FinancialSummary.fromJson(
        (json['data'] as Map).cast<String, dynamic>());
  }

  Future<List<MonthTotal>> financialOverview() async {
    final json =
        await _client.get<Map<String, dynamic>>('/api/financials/overview');
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (data['by_month'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MonthTotal.fromJson)
        .toList(growable: false);
  }

  Future<List<Invoice>> invoices({int perPage = 50}) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/invoices',
      query: {'per_page': '$perPage'},
    );
    return _data(json, Invoice.fromJson);
  }

  Future<List<Payment>> payments({int perPage = 50}) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/payments',
      query: {'per_page': '$perPage'},
    );
    return _data(json, Payment.fromJson);
  }

  Future<List<Product>> products({String? query, int perPage = 50}) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/products',
      query: {
        'per_page': '$perPage',
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return _data(json, Product.fromJson);
  }

  /// Broadcasts return a bare `data` list with no `meta`, unlike the
  /// resource endpoints.
  Future<List<Broadcast>> broadcasts() async {
    final json = await _client.get<Map<String, dynamic>>('/api/broadcasts');
    return _data(json, Broadcast.fromJson);
  }

  Future<int> unreadBroadcastCount() async {
    final json = await _client
        .get<Map<String, dynamic>>('/api/broadcasts/unread-count');
    return asIntField(json, 'unread');
  }

  /// Marks one broadcast read. The reviewer account holds
  /// `api.broadcasts.write` precisely so this works; it is the only write the
  /// app performs.
  Future<void> markBroadcastRead(String id) async {
    await _client.post<Map<String, dynamic>>('/api/broadcasts/$id/read');
  }
}

int asIntField(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? 0}') ?? 0;
}
