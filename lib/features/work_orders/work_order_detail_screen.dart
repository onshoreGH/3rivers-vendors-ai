import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/three_rivers_api.dart';
import '../../core/models/shipment.dart';
import '../../core/models/work_order.dart';
import '../../widgets/async_view.dart';
import '../../widgets/formatting.dart';
import '../shipments/shipment_detail_screen.dart';

class WorkOrderDetailScreen extends StatefulWidget {
  final String id;
  const WorkOrderDetailScreen({super.key, required this.id});

  @override
  State<WorkOrderDetailScreen> createState() => _WorkOrderDetailScreenState();
}

class _WorkOrderDetailScreenState extends State<WorkOrderDetailScreen> {
  late Future<({WorkOrder workOrder, List<Shipment> shipments})> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ThreeRiversApi>().workOrder(widget.id);
  }

  Future<void> _reload() {
    setState(
        () => _future = context.read<ThreeRiversApi>().workOrder(widget.id));
    return _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work Order')),
      body: FutureBuilder<({WorkOrder workOrder, List<Shipment> shipments})>(
        future: _future,
        builder: (context, snapshot) =>
            AsyncView<({WorkOrder workOrder, List<Shipment> shipments})>(
          snapshot: snapshot,
          onRetry: _reload,
          isEmpty: (_) => false,
          emptyState: const SizedBox(),
          builder: (data) {
            final wo = data.workOrder;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(wo.number.isEmpty ? wo.productName : wo.number,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _Tag(wo.isOverdue ? 'Overdue' : wo.status),
                  _Tag('${wo.priority} priority'),
                ]),
                const SizedBox(height: 16),
                Card(
                  child: Column(children: [
                    _Row('Product', wo.productName),
                    _Row('SKU', wo.productSku),
                    _Row('Quantity', '${wo.quantity}'),
                    _Row('Due date', shortDate(wo.dueDate)),
                    _Row('Status', prettyStatus(wo.status)),
                    _Row('Priority', wo.priority),
                    if (wo.createdBy.isNotEmpty) _Row('Created by', wo.createdBy),
                    if (wo.createdAt != null)
                      _Row('Created', relativeDate(wo.createdAt!)),
                  ]),
                ),
                if (wo.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(wo.notes, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 20),
                Text('Shipments (${data.shipments.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                if (data.shipments.isEmpty)
                  Text('No shipments linked to this work order.',
                      style: Theme.of(context).textTheme.bodyMedium)
                else
                  for (final s in data.shipments)
                    Card(
                      child: ListTile(
                        title: Text(s.number.isEmpty ? s.carrier : s.number),
                        subtitle: Text([
                          s.carrier,
                          if (s.lane.isNotEmpty) s.lane,
                          prettyStatus(s.status),
                        ].where((e) => e.isNotEmpty).join(' · ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    ShipmentDetailScreen(id: s.id))),
                      ),
                    ),
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
