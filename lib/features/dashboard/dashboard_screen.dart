import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/three_rivers_api.dart';
import '../../core/models/dashboard.dart';
import '../../state/auth_controller.dart';
import '../../widgets/async_view.dart';
import '../../widgets/formatting.dart';
import '../shipments/shipment_detail_screen.dart';
import '../work_orders/work_order_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Dashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ThreeRiversApi>().dashboard();
  }

  Future<void> _reload() {
    setState(() => _future = context.read<ThreeRiversApi>().dashboard());
    return _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        context.select<AuthController, String?>((a) => a.profile?.firstName);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: FutureBuilder<Dashboard>(
        future: _future,
        builder: (context, snapshot) => AsyncView<Dashboard>(
          snapshot: snapshot,
          onRetry: _reload,
          isEmpty: (_) => false,
          emptyState: const SizedBox(),
          builder: (d) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                (firstName != null && firstName.isNotEmpty)
                    ? 'Hi, $firstName'
                    : 'Operations overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Stat(
                        label: 'Work orders',
                        value: '${d.workOrders}',
                        icon: Icons.assignment_outlined),
                    const SizedBox(width: 10),
                    _Stat(
                        label: 'Shipments',
                        value: '${d.shipments}',
                        icon: Icons.local_shipping_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Stat(
                        label: 'Suppliers',
                        value: '${d.suppliers}',
                        icon: Icons.factory_outlined),
                    const SizedBox(width: 10),
                    _Stat(
                        label: 'Vendors',
                        value: '${d.vendors}',
                        icon: Icons.storefront_outlined),
                  ],
                ),
              ),
              if (d.overdueWorkOrders.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionHeader(
                    'Overdue work orders', d.workOrdersOverdue),
                for (final wo in d.overdueWorkOrders)
                  Card(
                    child: ListTile(
                      title: Text(wo.number.isEmpty ? wo.productName : wo.number),
                      subtitle: Text(
                          '${wo.productName} · due ${shortDate(wo.dueDate)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => WorkOrderDetailScreen(id: wo.id))),
                    ),
                  ),
              ],
              if (d.overdueShipments.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionHeader('Late shipments', d.shipmentsOverdue),
                for (final s in d.overdueShipments)
                  Card(
                    child: ListTile(
                      title: Text(s.number.isEmpty ? s.carrier : s.number),
                      subtitle: Text(
                        [s.carrier, if (s.lane.isNotEmpty) s.lane, 'ETA ${shortDate(s.etaDate)}']
                            .where((e) => e.isNotEmpty)
                            .join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ShipmentDetailScreen(id: s.id))),
                    ),
                  ),
              ],
              if (d.overdueWorkOrders.isEmpty && d.overdueShipments.isEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary),
                    title: const Text('Nothing overdue'),
                    subtitle: const Text(
                        'All open work orders and shipments are on schedule.'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader(this.label, this.count);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text('$count',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
