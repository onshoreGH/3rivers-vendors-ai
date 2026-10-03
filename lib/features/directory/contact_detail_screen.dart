import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/three_rivers_api.dart';
import '../../core/models/contact.dart';
import '../../widgets/async_view.dart';
import '../../widgets/formatting.dart';

class ContactDetailScreen extends StatefulWidget {
  final String contactType;
  final String contactId;
  final String name;

  const ContactDetailScreen({
    super.key,
    required this.contactType,
    required this.contactId,
    required this.name,
  });

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  late Future<({Contact contact, List<CheckInSession> sessions})> _future;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _future = context
        .read<ThreeRiversApi>()
        .directoryEntry(widget.contactType, widget.contactId);
  }

  Future<void> _reload() {
    setState(() => _future = context
        .read<ThreeRiversApi>()
        .directoryEntry(widget.contactType, widget.contactId));
    return _future.then((_) {}, onError: (_) {});
  }

  Future<void> _startCheckIn() async {
    setState(() => _starting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final invite = await context
          .read<ThreeRiversApi>()
          .startCheckIn(widget.contactType, widget.contactId);
      final opened = await launchUrl(
        Uri.parse(invite.hostUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Could not open the check-in room.')));
      }
      await _reload();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: FutureBuilder<({Contact contact, List<CheckInSession> sessions})>(
        future: _future,
        builder: (context, snapshot) => AsyncView<
            ({Contact contact, List<CheckInSession> sessions})>(
          snapshot: snapshot,
          onRetry: _reload,
          isEmpty: (_) => false,
          emptyState: const SizedBox(),
          builder: (data) {
            final c = data.contact;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                        radius: 26, child: Text(c.initials)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style:
                                  Theme.of(context).textTheme.titleLarge),
                          Text(c.typeLabel,
                              style:
                                  Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (c.email != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(c.email!),
                      onTap: () => launchUrl(Uri.parse('mailto:${c.email}')),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _starting ? null : _startCheckIn,
                  icon: _starting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.videocam_outlined),
                  label: Text(_starting
                      ? 'Starting…'
                      : 'Start video check-in'),
                ),
                const SizedBox(height: 6),
                Text(
                  'Opens a live room and creates a guest link the '
                  '${c.typeLabel.toLowerCase()} can join.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Text('Recent check-ins',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                if (data.sessions.isEmpty)
                  Text('No check-ins yet.',
                      style: Theme.of(context).textTheme.bodyMedium)
                else
                  for (final s in data.sessions.take(20))
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.videocam_outlined),
                        title: Text(prettyStatus(s.status)),
                        subtitle: Text([
                          if (s.initiatedBy.isNotEmpty) s.initiatedBy,
                          if (s.createdAt != null) relativeDate(s.createdAt!),
                        ].join(' · ')),
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
