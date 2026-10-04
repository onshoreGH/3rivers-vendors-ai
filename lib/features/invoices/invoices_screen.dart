import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/vendors_api.dart';
import '../../core/models/vendor_models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/formatting.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late Future<List<Invoice>> _future;
  bool _pastDueOnly = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<VendorsApi>().invoices();
  }

  Future<void> _reload() {
    setState(() => _future = context.read<VendorsApi>().invoices());
    return _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            tooltip: _pastDueOnly ? 'Show all' : 'Past due only',
            icon: Icon(
                _pastDueOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _pastDueOnly = !_pastDueOnly),
          ),
        ],
      ),
      body: FutureBuilder<List<Invoice>>(
        future: _future,
        builder: (context, snapshot) => AsyncView<List<Invoice>>(
          snapshot: snapshot,
          onRetry: _reload,
          isEmpty: (l) => l.isEmpty,
          emptyState: const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No invoices',
            detail: 'Invoices raised against your account appear here.',
          ),
          builder: (all) {
            final items =
                _pastDueOnly ? all.where((i) => i.isPastDue).toList() : all;

            // Filtering to an empty result is a different situation from
            // having no invoices at all, and saying so avoids the dead end of
            // an empty screen with an active filter the user has forgotten.
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 64),
                  EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'Nothing past due',
                    detail: 'Every invoice is within its payment terms.',
                  ),
                ],
              );
            }

            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _InvoiceTile(invoice: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pastDue = invoice.isPastDue;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(invoice.number,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invoice.customerName),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  pastDue
                      ? Icons.event_busy_outlined
                      : Icons.event_available_outlined,
                  size: 15,
                  color: pastDue
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  // Deliberately "Due", never "Unpaid": the invoices endpoint
                  // carries no settlement flag, so a paid/unpaid label here
                  // would be a guess shown as fact.
                  pastDue
                      ? 'Due ${shortDate(invoice.dueDate)} - past due'
                      : 'Due ${shortDate(invoice.dueDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: pastDue
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      trailing: Text(
        formatMoney(invoice.amount),
        style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
