import 'json.dart';

class WorkOrder {
  final String id;
  final String number;
  final String productSku;
  final String productName;
  final int quantity;
  final String? dueDate; // YYYY-MM-DD
  final String priority; // Low | Normal | High
  final String status; // Planned | Released | InProgress | Complete | Cancelled
  final String notes;
  final String createdBy;
  final DateTime? createdAt;

  const WorkOrder({
    required this.id,
    required this.number,
    required this.productSku,
    required this.productName,
    required this.quantity,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isOpen =>
      !const {'complete', 'done', 'cancelled', 'canceled'}
          .contains(status.toLowerCase());

  bool get isOverdue {
    if (!isOpen) return false;
    final d = parseDate(dueDate);
    return d != null && d.isBefore(DateTime.now());
  }

  factory WorkOrder.fromJson(Map<String, dynamic> json) => WorkOrder(
        id: asString(json['id']),
        number: asString(json['wo_number']),
        productSku: asString(json['product_sku']),
        productName: asString(json['product_name']),
        quantity: asInt(json['quantity']),
        dueDate: json['due_date'] == null ? null : asString(json['due_date']),
        priority: asString(json['priority'], 'Normal'),
        status: asString(json['status'], 'Planned'),
        notes: asString(json['notes']),
        createdBy: asString(json['created_by']),
        createdAt: parseDate(json['created_at']),
      );
}
