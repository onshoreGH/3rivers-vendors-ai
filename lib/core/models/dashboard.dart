import 'json.dart';
import 'work_order.dart';
import 'shipment.dart';

class Dashboard {
  final int suppliers;
  final int vendors;
  final int workOrders;
  final int shipments;
  final int workOrdersOverdue;
  final int shipmentsOverdue;
  final Map<String, int> workOrdersByStatus;
  final Map<String, int> shipmentsByStatus;
  final List<WorkOrder> overdueWorkOrders;
  final List<Shipment> overdueShipments;

  const Dashboard({
    required this.suppliers,
    required this.vendors,
    required this.workOrders,
    required this.shipments,
    required this.workOrdersOverdue,
    required this.shipmentsOverdue,
    required this.workOrdersByStatus,
    required this.shipmentsByStatus,
    required this.overdueWorkOrders,
    required this.overdueShipments,
  });

  static Map<String, int> _counts(dynamic v) {
    if (v is! Map) return const {};
    return v.map((k, val) => MapEntry(k.toString(), asInt(val)));
  }

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final c = (json['counts'] as Map?) ?? const {};
    List<T> list<T>(dynamic raw, T Function(Map<String, dynamic>) f) =>
        (raw is List)
            ? raw
                .whereType<Map>()
                .map((e) => f(e.cast<String, dynamic>()))
                .toList(growable: false)
            : const [];
    return Dashboard(
      suppliers: asInt(c['suppliers']),
      vendors: asInt(c['vendors']),
      workOrders: asInt(c['work_orders']),
      shipments: asInt(c['shipments']),
      workOrdersOverdue: asInt(c['work_orders_overdue']),
      shipmentsOverdue: asInt(c['shipments_overdue']),
      workOrdersByStatus: _counts(json['work_orders_by_status']),
      shipmentsByStatus: _counts(json['shipments_by_status']),
      overdueWorkOrders: list(json['overdue_work_orders'], WorkOrder.fromJson),
      overdueShipments: list(json['overdue_shipments'], Shipment.fromJson),
    );
  }
}
