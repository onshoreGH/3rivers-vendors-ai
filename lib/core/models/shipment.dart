import 'json.dart';

class Shipment {
  final String id;
  final String number;
  final String workOrderNumber;
  final String carrier;
  final String mode; // Ground | Air | Ocean | Rail | Other
  final String trackingNumber;
  final String origin;
  final String destination;
  final String? shipDate;
  final String? etaDate;
  final String status; // Planned | Shipped | InTransit | Delivered | Exception | Cancelled
  final int pieces;
  final double weightLbs;
  final String notes;
  final DateTime? createdAt;

  const Shipment({
    required this.id,
    required this.number,
    required this.workOrderNumber,
    required this.carrier,
    required this.mode,
    required this.trackingNumber,
    required this.origin,
    required this.destination,
    required this.shipDate,
    required this.etaDate,
    required this.status,
    required this.pieces,
    required this.weightLbs,
    required this.notes,
    required this.createdAt,
  });

  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isException => status.toLowerCase() == 'exception';

  bool get isLate {
    if (isDelivered || status.toLowerCase() == 'cancelled') return false;
    final d = parseDate(etaDate);
    return d != null && d.isBefore(DateTime.now());
  }

  String get lane {
    final o = origin.trim(), d = destination.trim();
    if (o.isEmpty && d.isEmpty) return '';
    return '${o.isEmpty ? '?' : o} → ${d.isEmpty ? '?' : d}';
  }

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
        id: asString(json['id']),
        number: asString(json['shipment_number']),
        workOrderNumber: asString(json['work_order_number']),
        carrier: asString(json['carrier']),
        mode: asString(json['mode'], 'Ground'),
        trackingNumber: asString(json['tracking_number']),
        origin: asString(json['origin']),
        destination: asString(json['destination']),
        shipDate: json['ship_date'] == null ? null : asString(json['ship_date']),
        etaDate: json['eta_date'] == null ? null : asString(json['eta_date']),
        status: asString(json['status'], 'Planned'),
        pieces: asInt(json['pieces'], 1),
        weightLbs: (json['weight_lbs'] is num)
            ? (json['weight_lbs'] as num).toDouble()
            : double.tryParse('${json['weight_lbs']}') ?? 0,
        notes: asString(json['notes']),
        createdAt: parseDate(json['created_at']),
      );
}
