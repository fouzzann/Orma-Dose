import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:orma_dose/main.dart';
import 'package:orma_dose/providers/app_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Orma Dose launch smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStateProvider(),
        child: const MyApp(),
      ),
    );

    // Allow async state loading to complete
    await tester.pumpAndSettle();

    // Verify that the Orma Dose main branding is visible
    expect(find.text('Orma Dose'), findsWidgets);
  });
}
