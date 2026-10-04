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

/// Invoices plus the set of invoice ids that have a payment against them.
///
/// The invoices endpoint carries no settlement flag, and showing "past due"
/// from the due date alone labelled every settled invoice overdue -- four of
/// them in the first walkthrough. Payments carry invoice_id, so the two are
/// joined here rather than leaving the screen to assert something false.
typedef _Ledger = ({List<Invoice> invoices, Set<String> paidIds});

class _InvoicesScreenState extends State<InvoicesScreen> {
  late Future<_Ledger> _future;
  bool _pastDueOnly = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Ledger> _load() async {
    final api = context.read<VendorsApi>();
    final results = await Future.wait([api.invoices(), api.payments()]);
    final invoices = results[0] as List<Invoice>;
    final payments = results[1] as List<Payment>;
    return (
      invoices: invoices,
      paidIds: payments.map((p) => p.invoiceId).where((id) => id.isNotEmpty).toSet(),
    );
  }

  Future<void> _reload() {
    setState(() => _future = _load());
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
      body: FutureBuilder<_Ledger>(
        future: _future,
        builder: (context, snapshot) => AsyncView<_Ledger>(
          snapshot: snapshot,
          onRetry: _reload,
          isEmpty: (l) => l.invoices.isEmpty,
          emptyState: const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No invoices',
            detail: 'Invoices raised against your account appear here.',
          ),
          builder: (ledger) {
            bool paid(Invoice i) => ledger.paidIds.contains(i.id);
            final items = _pastDueOnly
                ? ledger.invoices
                    .where((i) => i.isPastDue && !paid(i))
                    .toList()
                : ledger.invoices;

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
              itemBuilder: (context, i) =>
                  _InvoiceTile(invoice: items[i], paid: paid(items[i])),
            );
          },
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  final bool paid;
  const _InvoiceTile({required this.invoice, required this.paid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A settled invoice is never past due, however old its due date.
    final pastDue = invoice.isPastDue && !paid;

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
                  paid
                      ? Icons.check_circle_outline
                      : pastDue
                          ? Icons.event_busy_outlined
                          : Icons.event_available_outlined,
                  size: 15,
                  color: paid
                      ? theme.colorScheme.primary
                      : pastDue
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  paid
                      ? 'Paid'
                      : pastDue
                          ? 'Due ${shortDate(invoice.dueDate)} - past due'
                          : 'Due ${shortDate(invoice.dueDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: paid
                        ? theme.colorScheme.primary
                        : pastDue
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
