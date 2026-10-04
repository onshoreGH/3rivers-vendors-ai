import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/vendors_api.dart';
import '../../core/models/vendor_models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/formatting.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  late Future<List<Product>> _future;
  final _search = TextEditingController();
  bool _activeOnly = true;

  @override
  void initState() {
    super.initState();
    _future = context.read<VendorsApi>().products();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() {
    setState(() => _future = context.read<VendorsApi>().products());
    return _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          IconButton(
            tooltip: _activeOnly ? 'Show discontinued' : 'Active only',
            icon:
                Icon(_activeOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _activeOnly = !_activeOnly),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SearchBar(
              controller: _search,
              hintText: 'Search name or SKU',
              leading: const Icon(Icons.search),
              // Filtered client-side over the already-loaded page rather than
              // re-querying per keystroke: the catalogue is small and a
              // request per character would be rate-limit bait.
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) => AsyncView<List<Product>>(
          snapshot: snapshot,
          onRetry: _reload,
          isEmpty: (l) => l.isEmpty,
          emptyState: const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products',
            detail: 'Catalogue items for your account appear here.',
          ),
          builder: (all) {
            final q = _search.text.trim().toLowerCase();
            final items = all.where((p) {
              if (_activeOnly && !p.isActive) return false;
              if (q.isEmpty) return true;
              return p.name.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q);
            }).toList();

            if (items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 64),
                  EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'Nothing matches',
                    detail: q.isEmpty
                        ? 'No active items. Use the filter to include discontinued products.'
                        : 'No product matches "${_search.text.trim()}".',
                  ),
                ],
              );
            }

            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _ProductTile(product: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      title: Row(
        children: [
          Expanded(
            child: Text(product.name,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          if (!product.isActive)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusTint(context, product.status),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(prettyStatus(product.status),
                  style: theme.textTheme.labelSmall),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.sku,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(product.description,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Text(
              '${product.quantity} ${product.uom} on hand',
              style: theme.textTheme.bodySmall?.copyWith(
                color: product.quantity == 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      trailing: Text(formatMoney(product.price),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}
