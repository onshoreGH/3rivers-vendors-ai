import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/three_rivers_api.dart';
import '../../core/models/shipment.dart';
import '../../widgets/async_view.dart';
import '../../widgets/formatting.dart';
import 'shipment_detail_screen.dart';

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  late Future<List<Shipment>> _future;
  bool _activeOnly = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<ThreeRiversApi>().shipments();
  }

  Future<void> _reload() {
    setState(() => _future = context.read<ThreeRiversApi>().shipments());
    return _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipments'),
        actions: [
          IconButton(
            tooltip: _activeOnly ? 'Show all' : 'In transit only',
            icon: Icon(
                _activeOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _activeOnly = !_activeOnly),
          ),
        ],
      ),
      body: FutureBuilder<List<Shipment>>(
        future: _future,
        builder: (context, snapshot) => AsyncView<List<Shipment>>(
          snapshot: snapshot,
          onRetry: _reload,
          isEmpty: (l) => l.isEmpty,
          emptyState: const EmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'No shipments',
            detail: 'Shipments created in the 3Rivers portal appear here.',
          ),
          builder: (all) {
            final items = _activeOnly
                ? all.where((s) => !s.isDelivered).toList()
                : all;
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.check_circle_outline,
                title: 'Nothing in transit',
                detail: 'Every shipment has been delivered.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _ShipmentCard(s: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final Shipment s;
  const _ShipmentCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ShipmentDetailScreen(id: s.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.number.isEmpty ? s.carrier : s.number,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _Chip(label: s.isLate ? 'Late' : s.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (s.carrier.isNotEmpty) s.carrier,
                  if (s.lane.isNotEmpty) s.lane,
                  if (s.etaDate != null) 'ETA ${shortDate(s.etaDate)}',
                ].join(' · '),
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
