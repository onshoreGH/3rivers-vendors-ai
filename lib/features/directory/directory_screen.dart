import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/three_rivers_api.dart';
import '../../core/models/contact.dart';
import '../../widgets/async_view.dart';
import 'contact_detail_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  late Future<List<Contact>> _future;
  String _filter = 'all'; // all | supplier | vendor

  @override
  void initState() {
    super.initState();
    _future = context.read<ThreeRiversApi>().directory();
  }

  Future<void> _reload() {
    setState(() => _future = context.read<ThreeRiversApi>().directory());
    return _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Directory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'supplier', label: Text('Suppliers')),
                ButtonSegment(value: 'vendor', label: Text('Vendors')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
              showSelectedIcon: false,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Contact>>(
              future: _future,
              builder: (context, snapshot) => AsyncView<List<Contact>>(
                snapshot: snapshot,
                onRetry: _reload,
                isEmpty: (l) => l.isEmpty,
                emptyState: const EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No contacts',
                  detail:
                      'Suppliers and vendors added in the 3Rivers portal appear here.',
                ),
                builder: (all) {
                  final items = _filter == 'all'
                      ? all
                      : all.where((c) => c.contactType == _filter).toList();
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.groups_outlined,
                      title: 'No ${_filter}s',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = items[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(c.initials)),
                          title: Text(c.name),
                          subtitle: Text(
                            [c.typeLabel, if (c.email != null) c.email!]
                                .join(' · '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => ContactDetailScreen(
                                      contactType: c.contactType,
                                      contactId: c.id,
                                      name: c.name,
                                    )),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
