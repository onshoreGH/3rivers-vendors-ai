import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/three_rivers_api.dart';
import '../../core/models/work_order.dart';
import '../../widgets/async_view.dart';
import '../../widgets/formatting.dart';
import 'work_order_detail_screen.dart';

class WorkOrdersScreen extends StatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  State<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends State<WorkOrdersScreen> {
  late Future<List<WorkOrder>> _future;
  bool _openOnly = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<ThreeRiversApi>().workOrders();
  }

  Future<void> _reload() {
    setState(() => _future = context.read<ThreeRiversApi>().workOrders());
    return _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Orders'),
        actions: [
          IconButton(
            tooltip: _openOnly ? 'Show all' : 'Open only',
            icon: Icon(_openOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _openOnly = !_openOnly),
          ),
        ],
      ),
      body: FutureBuilder<List<WorkOrder>>(
        future: _future,
        builder: (context, snapshot) => AsyncView<List<WorkOrder>>(
          snapshot: snapshot,
          onRetry: _reload,
          isEmpty: (l) => l.isEmpty,
          emptyState: const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No work orders',
            detail: 'Work orders created in the 3Rivers portal appear here.',
          ),
          builder: (all) {
            final items =
                _openOnly ? all.where((w) => w.isOpen).toList() : all;
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.check_circle_outline,
                title: 'No open work orders',
                detail: 'Every work order is complete or cancelled.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _WorkOrderCard(wo: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _WorkOrderCard extends StatelessWidget {
  final WorkOrder wo;
  const _WorkOrderCard({required this.wo});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WorkOrderDetailScreen(id: wo.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      wo.number.isEmpty ? wo.productName : wo.number,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _Chip(label: wo.isOverdue ? 'Overdue' : wo.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  wo.productName,
                  'Qty ${wo.quantity}',
                  if (wo.dueDate != null) 'due ${shortDate(wo.dueDate)}',
                ].where((e) => e.isNotEmpty).join(' · '),
                style: text.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusTint(context, label),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(prettyStatus(label),
            style: Theme.of(context).textTheme.labelMedium),
      );
}
