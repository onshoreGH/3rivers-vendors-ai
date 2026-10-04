import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/vendors_api.dart';
import '../../core/models/vendor_models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/formatting.dart';

class BroadcastsScreen extends StatefulWidget {
  const BroadcastsScreen({super.key});

  @override
  State<BroadcastsScreen> createState() => _BroadcastsScreenState();
}

class _BroadcastsScreenState extends State<BroadcastsScreen> {
  late Future<List<Broadcast>> _future;

  /// Ids marked read in this session. The list is re-fetched on pull-to-
  /// refresh, but marking read must change the row immediately -- waiting on a
  /// round trip to grey out a notice feels broken.
  final _locallyRead = <String>{};

  @override
  void initState() {
    super.initState();
    _future = context.read<VendorsApi>().broadcasts();
  }

  Future<void> _reload() {
    setState(() {
      _locallyRead.clear();
      _future = context.read<VendorsApi>().broadcasts();
    });
    return _future.then((_) {}, onError: (_) {});
  }

  Future<void> _open(Broadcast b) async {
    final wasUnread = !b.isRead && !_locallyRead.contains(b.id);
    if (wasUnread) {
      setState(() => _locallyRead.add(b.id));
      try {
        await context.read<VendorsApi>().markBroadcastRead(b.id);
      } catch (_) {
        // Roll the optimistic update back rather than leaving the row
        // showing read when the server never recorded it.
        if (mounted) setState(() => _locallyRead.remove(b.id));
      }
    }

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _BroadcastSheet(broadcast: b),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: FutureBuilder<List<Broadcast>>(
        future: _future,
        builder: (context, snapshot) => AsyncView<List<Broadcast>>(
          snapshot: snapshot,
          onRetry: _reload,
          isEmpty: (l) => l.isEmpty,
          emptyState: const EmptyState(
            icon: Icons.campaign_outlined,
            title: 'No notices',
            detail: 'Announcements from 3Rivers appear here.',
          ),
          builder: (items) => ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = items[i];
              final read = b.isRead || _locallyRead.contains(b.id);
              return _BroadcastTile(
                broadcast: b,
                read: read,
                onTap: () => _open(b),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BroadcastTile extends StatelessWidget {
  final Broadcast broadcast;
  final bool read;
  final VoidCallback onTap;

  const _BroadcastTile({
    required this.broadcast,
    required this.read,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Icon(
        read ? Icons.drafts_outlined : Icons.mark_email_unread_outlined,
        color: read
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.primary,
      ),
      title: Text(
        broadcast.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: read ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              broadcast.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              broadcast.createdAt == null
                  ? '—'
                  : relativeDate(broadcast.createdAt!),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _BroadcastSheet extends StatelessWidget {
  final Broadcast broadcast;
  const _BroadcastSheet({required this.broadcast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(broadcast.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              broadcast.createdAt == null
                  ? '—'
                  : fullDate(broadcast.createdAt!),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(broadcast.message,
                    style: theme.textTheme.bodyLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
