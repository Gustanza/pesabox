import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_box_app/i18n/i18n.dart';
import 'package:pesa_box_app/screens/dashboard/dashboard_nav_bar.dart';

void main() {
  tearDown(() => I18n.locale.value = 'sw');

  testWidgets('bottom bar shows all five tabs (Swahili)', (tester) async {
    I18n.locale.value = 'sw';
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(bottomNavigationBar: DashboardNavBar())),
    );

    for (final label in ['Mwanzo', 'Kikundi', 'Mikutano', 'Shughuli', 'Wasifu']) {
      expect(find.text(label), findsOneWidget, reason: 'missing tab $label');
    }
  });

  testWidgets('bottom bar shows all five tabs (English)', (tester) async {
    I18n.locale.value = 'en';
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(bottomNavigationBar: DashboardNavBar())),
    );

    for (final label in ['Home', 'Group', 'Meetings', 'Activity', 'Profile']) {
      expect(find.text(label), findsOneWidget, reason: 'missing tab $label');
    }
  });
}
