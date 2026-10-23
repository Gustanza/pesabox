import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_box_app/i18n/i18n.dart';
import 'package:pesa_box_app/screens/loans/loan_purpose.dart';
import 'package:pesa_box_app/screens/loans/record_loan_screen.dart';
import 'package:pesa_box_app/screens/members/dob_field.dart';
import 'package:pesa_box_app/services/app_data.dart';

void main() {
  setUp(() => I18n.locale.value = 'sw');
  tearDown(() => I18n.locale.value = 'sw');

  group('date of birth', () {
    test('age counts whole years and waits for the birthday', () {
      final now = DateTime(2026, 10, 23);
      expect(ageFromDob('1990-10-23', now: now), 36);
      expect(ageFromDob('1990-10-24', now: now), 35);
      expect(ageFromDob('1990-03-01T00:00:00Z', now: now), 36);
      expect(ageFromDob(null, now: now), isNull);
      expect(ageFromDob('not a date', now: now), isNull);
    });

    test('dates are sent as YYYY-MM-DD and shown with the age', () {
      expect(isoDay(DateTime(1990, 3, 7)), '1990-03-07');
      expect(dobWithAge('1990-03-07', now: DateTime(2026, 10, 23)), '07 Mac 1990 · Miaka 36');
      expect(dobWithAge(''), isNull);
    });

    testWidgets('the field shows the chosen date and can be cleared', (tester) async {
      String? value = '1990-03-07';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => DateOfBirthField(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ));
      expect(find.text('Tarehe ya kuzaliwa'), findsOneWidget);
      expect(find.text('07 Mac 1990'), findsOneWidget);
      await tester.tap(find.byTooltip('Futa'));
      await tester.pump();
      expect(value, isNull);
      expect(find.text('Chagua tarehe (si lazima)'), findsOneWidget);
    });
  });

  group('loan purpose', () {
    test('labels are translated, blank is "not specified"', () {
      expect(loanPurposeLabel('household'), 'Matumizi ya nyumbani');
      expect(loanPurposeLabel('livestock'), 'Mifugo');
      expect(loanPurposeLabel(null), 'Haijabainishwa');
      I18n.locale.value = 'en';
      expect(loanPurposeLabel('housing'), 'Housing');
      expect(loanPurposeLabel(''), 'Not specified');
    });

    test('only business, agriculture and livestock ask for an enterprise type', () {
      expect(kLoanPurposes.keys, [
        'business', 'agriculture', 'livestock', 'education', 'health',
        'household', 'housing', 'emergency', 'other',
      ]);
      expect(kLoanPurposes.keys.where(purposeNeedsEnterprise),
          ['business', 'agriculture', 'livestock']);
    });

    testWidgets('record loan: enterprise type appears for a business purpose only', (tester) async {
      AppState.I.group = {'id': null, 'loanInterestRate': 10, 'maxLoanPeriodMonths': 3};
      AppState.I.members = [
        {'id': 'm1', 'firstName': 'Asha', 'lastName': 'Juma'},
      ];
      addTearDown(() {
        AppState.I.group = null;
        AppState.I.members = [];
      });
      await tester.binding.setSurfaceSize(const Size(430, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: RecordLoanScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Madhumuni ya mkopo (si lazima)'), findsOneWidget);
      expect(find.byKey(const ValueKey('loan-enterprise')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('loan-purpose')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Biashara').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('loan-enterprise')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('loan-purpose')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimu').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('loan-enterprise')), findsNothing);
    });
  });
}
