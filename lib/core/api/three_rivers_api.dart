import '../models/contact.dart';
import '../models/dashboard.dart';
import '../models/inbox_message.dart';
import '../models/shipment.dart';
import '../models/user_profile.dart';
import '../models/work_order.dart';
import 'api_client.dart';

/// Staff-facing calls for the 3Rivers portal. Everything rides on the
/// Keycloak bearer token and hits the mobile API at `/api/v1/*`
/// (see `mobile_v1.py` on the portal — read-only for v1).
class ThreeRiversApi {
  final ApiClient _client;
  ThreeRiversApi(this._client);

  Future<UserProfile> me() async =>
      UserProfile.fromJson(await _client.get<Map<String, dynamic>>('/api/v1/me'));

  Future<Dashboard> dashboard() async => Dashboard.fromJson(
      await _client.get<Map<String, dynamic>>('/api/v1/dashboard'));

  List<T> _items<T>(Map<String, dynamic> json, T Function(Map<String, dynamic>) f) =>
      (json['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(f)
          .toList(growable: false);

  Future<List<WorkOrder>> workOrders({String? status}) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/v1/work-orders',
      query: status == null ? null : {'status': status},
    );
    return _items(json, WorkOrder.fromJson);
  }

  Future<({WorkOrder workOrder, List<Shipment> shipments})> workOrder(
      String id) async {
    final json =
        await _client.get<Map<String, dynamic>>('/api/v1/work-orders/$id');
    return (
      workOrder: WorkOrder.fromJson(
          (json['work_order'] as Map).cast<String, dynamic>()),
      shipments: (json['shipments'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Shipment.fromJson)
          .toList(growable: false),
    );
  }

  Future<List<Shipment>> shipments({String? status}) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/v1/shipments',
      query: status == null ? null : {'status': status},
    );
    return _items(json, Shipment.fromJson);
  }

  Future<({Shipment shipment, WorkOrder? workOrder})> shipment(String id) async {
    final json =
        await _client.get<Map<String, dynamic>>('/api/v1/shipments/$id');
    final wo = json['work_order'];
    return (
      shipment:
          Shipment.fromJson((json['shipment'] as Map).cast<String, dynamic>()),
      workOrder: wo is Map ? WorkOrder.fromJson(wo.cast<String, dynamic>()) : null,
    );
  }

  Future<List<Contact>> directory({String? kind}) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/v1/directory',
      query: kind == null ? null : {'kind': kind},
    );
    return _items(json, Contact.fromJson);
  }

  Future<({Contact contact, List<CheckInSession> sessions})> directoryEntry(
      String contactType, String contactId) async {
    final json = await _client.get<Map<String, dynamic>>(
        '/api/v1/directory/$contactType/$contactId');
    return (
      contact:
          Contact.fromJson((json['contact'] as Map).cast<String, dynamic>()),
      sessions: (json['sessions'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CheckInSession.fromJson)
          .toList(growable: false),
    );
  }

  Future<List<InboxMessage>> inbox() async {
    final json = await _client.get<Map<String, dynamic>>('/api/v1/inbox');
    return _items(json, InboxMessage.fromJson);
  }

  Future<CheckInInvite> startCheckIn(String contactType, String contactId) async =>
      CheckInInvite.fromJson(await _client.post<Map<String, dynamic>>(
          '/api/v1/directory/$contactType/$contactId/check-in'));
}
