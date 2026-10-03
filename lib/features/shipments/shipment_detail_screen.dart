import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/three_rivers_api.dart';
import '../../core/models/shipment.dart';
import '../../core/models/work_order.dart';
import '../../widgets/async_view.dart';
import '../../widgets/formatting.dart';
import '../work_orders/work_order_detail_screen.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final String id;
  const ShipmentDetailScreen({super.key, required this.id});

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  late Future<({Shipment shipment, WorkOrder? workOrder})> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ThreeRiversApi>().shipment(widget.id);
  }

  Future<void> _reload() {
    setState(
        () => _future = context.read<ThreeRiversApi>().shipment(widget.id));
    return _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shipment')),
      body: FutureBuilder<({Shipment shipment, WorkOrder? workOrder})>(
        future: _future,
        builder: (context, snapshot) =>
            AsyncView<({Shipment shipment, WorkOrder? workOrder})>(
          snapshot: snapshot,
          onRetry: _reload,
          isEmpty: (_) => false,
          emptyState: const SizedBox(),
          builder: (data) {
            final s = data.shipment;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(s.number.isEmpty ? s.carrier : s.number,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _Tag(s.isLate ? 'Late' : s.status),
                  _Tag(s.mode),
                ]),
                const SizedBox(height: 16),
                Card(
                  child: Column(children: [
                    _Row('Carrier', s.carrier),
                    _Row('Mode', s.mode),
                    _Row('Tracking', s.trackingNumber),
                    _Row('Origin', s.origin),
                    _Row('Destination', s.destination),
                    _Row('Ship date', shortDate(s.shipDate)),
                    _Row('ETA', shortDate(s.etaDate)),
                    _Row('Status', prettyStatus(s.status)),
                    _Row('Pieces', '${s.pieces}'),
                    if (s.weightLbs > 0)
                      _Row('Weight', '${s.weightLbs.toStringAsFixed(1)} lbs'),
                  ]),
                ),
                if (s.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(s.notes, style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (data.workOrder != null) ...[
                  const SizedBox(height: 20),
                  Text('Work order',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Card(
                    child: ListTile(
                      title: Text(data.workOrder!.number.isEmpty
                          ? data.workOrder!.productName
                          : data.workOrder!.number),
                      subtitle: Text(data.workOrder!.productName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => WorkOrderDetailScreen(
                              id: data.workOrder!.id))),
                    ),
                  ),
                ] else if (s.workOrderNumber.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Linked to work order ${s.workOrderNumber}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline)),
            ),
            Expanded(
                child: Text(value.isEmpty ? '—' : value,
                    style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statusTint(context, label),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(prettyStatus(label),
            style: Theme.of(context).textTheme.labelMedium),
      );
}
