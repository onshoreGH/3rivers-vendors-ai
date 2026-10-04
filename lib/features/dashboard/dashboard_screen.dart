import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/vendors_api.dart';
import '../../core/models/vendor_models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/formatting.dart';

typedef _Home = ({FinancialSummary summary, List<MonthTotal> months});

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_Home> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Home> _load() async {
    final api = context.read<VendorsApi>();
    // Both in flight together -- sequential awaits made the home screen the
    // slowest tab for no reason, since neither call depends on the other.
    final results = await Future.wait([
      api.financialSummary(),
      api.financialOverview(),
    ]);
    return (
      summary: results[0] as FinancialSummary,
      months: results[1] as List<MonthTotal>,
    );
  }

  Future<void> _reload() {
    setState(() => _future = _load());
    return _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: FutureBuilder<_Home>(
        future: _future,
        builder: (context, snapshot) => AsyncView<_Home>(
          snapshot: snapshot,
          onRetry: _reload,
          // Never "empty": a vendor with no activity still gets a real screen
          // showing zero, which is a fact rather than a blank page.
          isEmpty: (_) => false,
          emptyState: const SizedBox.shrink(),
          builder: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _RevenueCard(summary: data.summary),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'Invoices',
                      value: '${data.summary.invoicesCount}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.payments_outlined,
                      label: 'Payments',
                      value: '${data.summary.paymentsCount}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Payments by month',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _MonthlyBars(months: data.months,
                  currency: data.summary.currency),
              if (!data.summary.expensesAvailable) ...[
                const SizedBox(height: 20),
                const _ExpensesNotice(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final FinancialSummary summary;
  const _RevenueCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Received to date',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(
              formatMoney(summary.revenue, summary.currency),
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (summary.lastPaymentOn != null) ...[
              const SizedBox(height: 6),
              Text('Last payment ${shortDate(summary.lastPaymentOn)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Deliberately plain bars rather than a charting package: one dependency for
/// one view, and a dozen months of totals reads fine as proportional rows.
class _MonthlyBars extends StatelessWidget {
  final List<MonthTotal> months;
  final String currency;

  const _MonthlyBars({required this.months, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (months.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No payments recorded yet.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }

    // Guard the divisor: an all-zero set would otherwise divide by zero and
    // render NaN-width bars.
    final peak = months
        .map((m) => m.total)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            for (final m in months)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 62,
                      child: Text(m.month,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: peak <= 0 ? 0 : (m.total / peak),
                          minHeight: 9,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 86,
                      child: Text(
                        formatMoney(m.total, currency),
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The server reports expenses_available=false because it has no expense data
/// source at all. Saying so is the point: a zero in an Expenses box would be
/// read as "no expenses" when the truth is "not tracked here".
class _ExpensesNotice extends StatelessWidget {
  const _ExpensesNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Expense tracking is not part of this portal, so profit is not shown.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
