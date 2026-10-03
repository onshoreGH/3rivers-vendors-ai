import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../state/auth_controller.dart';
import '../../widgets/page_body.dart';
import '../legal/legal_document_screen.dart';
import 'delete_account_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const config = ThreeRiversConfig();
    final auth = context.watch<AuthController>();
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageBody(
        child: ListView(
        children: [
          if (profile != null)
            ListTile(
              leading: CircleAvatar(child: Text(profile.initials)),
              title: Text(profile.fullName.isEmpty
                  ? profile.email
                  : profile.fullName),
              subtitle: Text([
                profile.email,
                profile.roleLabel,
              ].where((s) => s.isNotEmpty).join('\n')),
              isThreeLine: true,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Contact support'),
            subtitle: Text(config.supportEmail),
            onTap: () => launchUrl(Uri(
              scheme: 'mailto',
              path: config.supportEmail,
              query: 'subject=${Uri.encodeComponent('${config.appName} support')}',
            )),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LegalDocumentScreen(
                title: 'Terms of Service',
                assetPath: config.termsAssetPath,
                canonicalUrl: config.termsUrl,
              ),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LegalDocumentScreen(
                title: 'Privacy Policy',
                assetPath: config.privacyAssetPath,
                canonicalUrl: config.privacyPolicyUrl,
              ),
            )),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Sign out',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign out')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<AuthController>().logout();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.no_accounts_outlined),
            title: const Text('Delete account'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const DeleteAccountScreen(),
            )),
          ),
          const SizedBox(height: 12),
          const _VersionFooter(),
          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final text = info == null
            ? ''
            : '${info.appName} ${info.version} (${info.buildNumber})';
        return Center(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        );
      },
    );
  }
}
