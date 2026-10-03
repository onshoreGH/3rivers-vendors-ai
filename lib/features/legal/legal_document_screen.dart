import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/page_body.dart';

/// Renders a bundled markdown legal document (terms / privacy) so it's
/// always available offline and during App Review, with a link out to the
/// canonical hosted version.
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String assetPath;
  final Uri canonicalUrl;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
    required this.canonicalUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open in browser',
            onPressed: () => launchUrl(canonicalUrl,
                mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return PageBody(
            child: Markdown(
              data: snapshot.data!,
              padding: const EdgeInsets.all(20),
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
