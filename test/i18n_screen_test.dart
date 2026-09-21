import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_box_app/i18n/i18n.dart';
import 'package:pesa_box_app/screens/profile/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ValueListenableBuilder<String>(
      valueListenable: I18n.locale,
      // Same rebuild-on-change approach as PesaBoxApp.
      builder: (context, code, _) => MaterialApp(
        key: ValueKey(code),
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    I18n.locale.value = 'sw';
  });

  testWidgets('settings screen shows Swahili by default', (tester) async {
    await _pump(tester);

    expect(find.text('Mipangilio'), findsOneWidget); // Settings (title)
    expect(find.text('Lugha'), findsOneWidget); // Language
    expect(find.text('Arifa'), findsOneWidget); // Notifications
    expect(find.text('Notifications'), findsNothing);
  });

  testWidgets('tapping English switches the screen and remembers the choice',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump();

    expect(I18n.locale.value, 'en');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Arifa'), findsNothing);

    final saved = (await SharedPreferences.getInstance()).getString('pb_lang');
    expect(saved, 'en');

    // ...and back again
    await tester.tap(find.text('Kiswahili'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Mipangilio'), findsOneWidget);
  });
}
