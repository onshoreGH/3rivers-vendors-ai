import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../state/auth_controller.dart';
import '../../widgets/page_body.dart';

/// Apple 5.1.1(v): an in-app way to request account deletion. 3Rivers
/// staff accounts are provisioned by an administrator, so deletion is a
/// request routed to support with the account context, then a local
/// sign-out.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _confirm = false;
  bool _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    const config = ThreeRiversConfig();
    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final email = auth.profile?.email ?? '(unknown)';

    final uri = Uri(
      scheme: 'mailto',
      path: config.supportEmail,
      query: 'subject=${Uri.encodeComponent('Account deletion request')}'
          '&body=${Uri.encodeComponent(
        'Please delete my Onshore 3Rivers account.\n\nAccount: $email\n',
      )}',
    );
    await launchUrl(uri);
    await auth.logout();
    messenger.showSnackBar(const SnackBar(
        content: Text('Deletion request started. You have been signed out.')));
    navigator.popUntil((r) => r.isFirst);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    const config = ThreeRiversConfig();
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Requesting account deletion',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '• Your request is sent to your 3Rivers administrator and to '
              'Onshore support.\n'
              '• Your access is closed and you are signed out.\n'
              '• Operational records (work orders, shipments, messages) stay '
              'in the 3Rivers system of record.\n'
              '• You will receive written confirmation by email.',
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _confirm,
              onChanged: (v) => setState(() => _confirm = v ?? false),
              title: const Text(
                  'I understand this closes my account and signs me out.'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: (!_confirm || _busy) ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Request account deletion'),
            ),
            const SizedBox(height: 12),
            Text('Questions? Email ${config.supportEmail}.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
