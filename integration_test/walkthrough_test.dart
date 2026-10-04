import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onshore_3rivers_vendors/main.dart' as app;

/// Drives the whole app against the LIVE Vendors API and captures a screenshot
/// per tab. Run with the reviewer credentials:
///
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/walkthrough_test.dart \
///     --dart-define=WALKTHROUGH_USER=... --dart-define=WALKTHROUGH_PASS=... \
///     -d <simulator id>
///
/// Credentials come from --dart-define, never literals: this file is committed.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const user = String.fromEnvironment('WALKTHROUGH_USER');
  const pass = String.fromEnvironment('WALKTHROUGH_PASS');

  testWidgets('vendor walkthrough', (tester) async {
    expect(user.isNotEmpty && pass.isNotEmpty, isTrue,
        reason: 'pass --dart-define=WALKTHROUGH_USER and WALKTHROUGH_PASS');

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // A persisted session from a previous run lands straight on the shell, so
    // the login step is conditional rather than assumed -- the Legal and
    // Educate drives both tripped over exactly this.
    final fields = find.byType(TextFormField);
    if (fields.evaluate().isNotEmpty) {
      await tester.enterText(fields.at(0), user);
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(1), pass);
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final signIn = find.byType(FilledButton);
      if (signIn.evaluate().isNotEmpty) {
        await tester.tap(signIn.first);
      }
      // Real network round trip against production, not a mock.
      await tester.pumpAndSettle(const Duration(seconds: 12));
      await binding.takeScreenshot('01-signed-in');
    }

    // Each tab: open it, let the request settle, prove something real
    // rendered, then capture.
    const tabs = <(String, String, String)>[
      ('Overview', '02-overview', 'Received to date'),
      ('Invoices', '03-invoices', 'INV-'),
      ('Catalogue', '04-catalogue', 'CRM-'),
      ('Notices', '05-notices', ''),
      ('Settings', '06-settings', ''),
    ];

    for (final (label, shot, expectText) in tabs) {
      final destination = find.text(label);
      expect(destination, findsWidgets, reason: 'no "$label" tab in the nav');
      await tester.tap(destination.last);
      await tester.pumpAndSettle(const Duration(seconds: 8));

      if (expectText.isNotEmpty) {
        // textContaining, not exact: this asserts real API data reached the
        // screen. An empty list or a spinner would pass a bare "did it not
        // crash" check, which is the failure mode worth catching.
        expect(find.textContaining(expectText), findsWidgets,
            reason: '$label rendered without live data containing "$expectText"');
      }

      await binding.takeScreenshot(shot);
    }

    // Tapping a notice opens the detail sheet and marks it read -- the only
    // write the app performs, and the one the reviewer role is granted for.
    await tester.tap(find.text('Notices').last);
    await tester.pumpAndSettle(const Duration(seconds: 6));
    final notice = find.textContaining('Payment run completed');
    if (notice.evaluate().isNotEmpty) {
      await tester.tap(notice.first);
      await tester.pumpAndSettle(const Duration(seconds: 4));
      await binding.takeScreenshot('07-notice-detail');
    }
  });
}
