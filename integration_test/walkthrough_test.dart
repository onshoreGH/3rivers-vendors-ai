// Drives the real app against the live 3Rivers API and captures a
// screenshot at each screen. Run via flutter drive with test_driver/.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onshore_3rivers_vendors/main.dart' as app;

const _username = String.fromEnvironment('WALK_USERNAME');
const _password = String.fromEnvironment('WALK_PASSWORD');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('walkthrough', (tester) async {
    await binding.convertFlutterSurfaceToImage();

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final needLogin = find.byType(TextFormField).evaluate().isNotEmpty;
    if (needLogin) {
      await _shot(binding, tester, '01-login');
      await tester.enterText(find.byType(TextFormField).first, _username);
      await tester.enterText(find.byType(TextFormField).at(1), _password);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.text('Home').evaluate().isNotEmpty) break;
      }
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _shot(binding, tester, '02-home');

    for (final tab in const [
      ('Work Orders', '03-work-orders'),
      ('Shipments', '04-shipments'),
      ('Directory', '05-directory'),
      ('Settings', '06-settings'),
    ]) {
      if (find.text(tab.$1).evaluate().isNotEmpty) {
        await tester.tap(find.text(tab.$1).last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await _shot(binding, tester, tab.$2);
      }
    }
  });
}

Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}
