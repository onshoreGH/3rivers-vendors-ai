import 'package:flutter_test/flutter_test.dart';
import 'package:onshore_3rivers_vendors/core/config/app_config.dart';
import 'package:onshore_3rivers_vendors/core/models/shipment.dart';
import 'package:onshore_3rivers_vendors/core/models/work_order.dart';

void main() {
  test('ThreeRiversConfig identity matches the App Store Connect record', () {
    const config = ThreeRiversConfig();
    expect(config.appName, 'Onshore 3Rivers AI');
    expect(config.bundleId, 'ai.onshoretech.onshore-3rivers-ai');
  });

  test('WorkOrder.isOverdue: open + past due', () {
    final wo = WorkOrder.fromJson({
      'id': '1',
      'wo_number': 'WO-1',
      'status': 'InProgress',
      'due_date': '2000-01-01',
      'quantity': 5,
    });
    expect(wo.isOpen, true);
    expect(wo.isOverdue, true);
  });

  test('WorkOrder.isOverdue: complete is never overdue', () {
    final wo = WorkOrder.fromJson({
      'id': '2',
      'status': 'Complete',
      'due_date': '2000-01-01',
    });
    expect(wo.isOpen, false);
    expect(wo.isOverdue, false);
  });

  test('Shipment.lane + isLate', () {
    final s = Shipment.fromJson({
      'id': 's1',
      'shipment_number': 'SHP-1',
      'origin': 'Detroit, MI',
      'destination': 'Chicago, IL',
      'status': 'InTransit',
      'eta_date': '2000-01-01',
    });
    expect(s.lane, 'Detroit, MI → Chicago, IL');
    expect(s.isLate, true);
    expect(s.isDelivered, false);
  });
}
