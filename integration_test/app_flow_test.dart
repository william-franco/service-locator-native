import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:service_locator_native/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads user info on home screen', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('User Info'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh_outlined));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.textContaining('User:'), findsWidgets);
  });
}