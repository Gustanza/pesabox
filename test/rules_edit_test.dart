import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_box_app/i18n/i18n.dart';
import 'package:pesa_box_app/screens/group/rules_edit_screen.dart';
import 'package:pesa_box_app/screens/loans/record_loan_screen.dart';
import 'package:pesa_box_app/screens/meetings/record_contribution_screen.dart';
import 'package:pesa_box_app/screens/meetings/record_social_fund_screen.dart';
import 'package:pesa_box_app/services/app_data.dart';
import 'package:pesa_box_app/services/graphql_client.dart';
import 'package:pesa_box_app/services/report_data.dart';

Map<String, dynamic> _rulesResponse() => {
      'canEdit': true,
      'services': ['Shares', 'Mandatory Savings', 'Voluntary Savings', 'Social Fund', 'Loans', 'Fines', 'Membership Fee'],
      'rules': {
        'mandatorySavingsAmount': 5000,
        'shareValue': 5000,
        'minShares': 1,
        'maxShares': 5,
        'socialFundContribution': 2000,
        'loanInterestRate': 10,
        'maxLoanPeriodMonths': 3,
        'maxLoanMultiplier': 0,
        'fineReasons': [
          {'reason': 'Late Attendance', 'amount': 1000},
          {'reason': 'Absent', 'amount': 2000},
        ],
        'enabledServices': ['Shares', 'Mandatory Savings', 'Social Fund', 'Loans', 'Fines'],
      },
    };

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(430, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => I18n.locale.value = 'sw');
  tearDown(() => I18n.locale.value = 'sw');

  testWidgets('the rules form loads the rules and saves the edited values', (tester) async {
    Map<String, dynamic>? saved;
    await _pump(
      tester,
      RulesEditScreen(
        load: () async => _rulesResponse(),
        save: (rules) async {
          saved = rules;
          return _rulesResponse();
        },
      ),
    );

    expect(find.text('Mabadiliko yanahusu rekodi mpya tu. Mikopo iliyopo inabaki na riba na jumla iliyotolewa nayo.'), findsOneWidget);
    expect(find.widgetWithText(TextField, '10'), findsOneWidget); // interest

    await tester.enterText(find.byKey(const ValueKey('rule-loanInterestRate')), '12');
    await tester.enterText(find.byKey(const ValueKey('rule-maxLoanMultiplier')), '3');
    await tester.tap(find.byTooltip('Ondoa').first); // drop "Late Attendance"
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('service-Fines'))); // switch Fines off
    await tester.pump();
    await tester.tap(find.text('Hifadhi kanuni'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!['loanInterestRate'], 12);
    expect(saved!['maxLoanMultiplier'], 3);
    expect(saved!['fineReasons'], [
      {'reason': 'Absent', 'amount': 2000},
    ]);
    expect(saved!['enabledServices'], ['Shares', 'Mandatory Savings', 'Social Fund', 'Loans']);
  });

  testWidgets('a rejected save shows the server message', (tester) async {
    await _pump(
      tester,
      RulesEditScreen(
        load: () async => _rulesResponse(),
        save: (_) async => throw const GraphQLException('Loan interest rate cannot be more than 100'),
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('rule-loanInterestRate')), '150');
    await tester.tap(find.text('Hifadhi kanuni'));
    await tester.pumpAndSettle();
    expect(find.text('Loan interest rate cannot be more than 100'), findsOneWidget);
  });

  test('flat interest preview and loan balances follow the stored terms', () {
    AppState.I.group = {'id': 'g1', 'loanInterestRate': 12, 'maxLoanPeriodMonths': 6};
    addTearDown(() => AppState.I.group = null);
    final p = AppState.I.loanPreview(100000);
    expect(p.interest, 12000);
    expect(p.totalDue, 112000);

    AppState.I.group = {'id': 'g1', 'loanInterestRate': 0};
    expect(AppState.I.loanPreview(50000).totalDue, 50000); // 0% is a real rate

    final legacy = {'amount': 50000, 'amountRepaid': 10000, 'interestRate': 10, 'status': 'active'};
    final fresh = {'amount': 100000, 'amountRepaid': 10000, 'interestAmount': 12000, 'totalDue': 112000, 'status': 'active'};
    expect(loanBalance(legacy), 40000); // issued before interest: principal only
    expect(loanInterest(legacy), 0);
    expect(loanBalance(fresh), 102000);
    expect(loanTotalDue(fresh), 112000);
  });

  test('disabled services are reported off; a group without the field uses the defaults', () {
    AppState.I.group = {'id': 'g1'};
    addTearDown(() => AppState.I.group = null);
    expect(AppState.I.serviceEnabled('Loans'), isTrue);
    AppState.I.group = {
      'id': 'g1',
      'enabledServices': ['Shares'],
    };
    expect(AppState.I.serviceEnabled('Loans'), isFalse);
    expect(AppState.I.savingsEnabled, isFalse);
  });

  testWidgets('record loan shows interest and total due before confirming', (tester) async {
    AppState.I.group = {'id': null, 'loanInterestRate': 12, 'maxLoanPeriodMonths': 6};
    AppState.I.members = [
      {'id': 'm1', 'firstName': 'Asha', 'lastName': 'Juma'},
    ];
    addTearDown(() {
      AppState.I.group = null;
      AppState.I.members = [];
    });
    await _pump(tester, const RecordLoanScreen());

    await tester.enterText(find.byType(TextField).first, '100000');
    await tester.pumpAndSettle();
    expect(find.text('TZS 12,000'), findsOneWidget); // interest
    expect(find.text('TZS 112,000'), findsOneWidget); // total to repay

    await tester.tap(find.text('Toa mkopo'));
    await tester.pumpAndSettle();
    expect(find.text('Thibitisha mkopo'), findsOneWidget);
    expect(find.textContaining('TZS 112,000 ya kurejesha ndani ya miezi 6'), findsOneWidget);
    await tester.tap(find.text('Ghairi'));
    await tester.pumpAndSettle();
    expect(find.text('Thibitisha mkopo'), findsNothing);
  });

  testWidgets('a rules screen that cannot load shows an error and a retry, not an empty form', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      RulesEditScreen(load: () async {
        calls++;
        if (calls == 1) throw const GraphQLException('Request failed (500)');
        return _rulesResponse();
      }),
    );
    expect(find.text('Imeshindwa kupakia kanuni za kikundi.'), findsOneWidget);
    expect(find.byKey(const ValueKey('rule-loanInterestRate')), findsNothing);
    expect(find.text('Hifadhi kanuni'), findsNothing);

    await tester.tap(find.text('Jaribu tena'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rule-loanInterestRate')), findsOneWidget);
    expect(find.widgetWithText(TextField, '10'), findsOneWidget);
  });

  testWidgets('the social fund amount is fixed when the rules set one', (tester) async {
    AppState.I.group = {'id': null, 'socialFundContribution': 2000};
    AppState.I.members = [
      {'id': 'm1', 'firstName': 'Asha', 'lastName': 'Juma'},
    ];
    addTearDown(() {
      AppState.I.group = null;
      AppState.I.members = [];
    });
    await _pump(tester, const RecordSocialFundScreen(meetingId: 'mt1'));
    final field = tester.widget<TextField>(find.byKey(const ValueKey('social-fund-amount')));
    expect(field.readOnly, isTrue);
    expect(field.controller!.text, '2000');
  });

  testWidgets('contributions: mandatory is fixed, voluntary is free when both are on', (tester) async {
    AppState.I.group = {
      'id': null,
      'mandatorySavingsAmount': 5000,
      'enabledServices': ['Mandatory Savings', 'Voluntary Savings'],
    };
    AppState.I.members = [
      {'id': 'm1', 'firstName': 'Asha', 'lastName': 'Juma'},
    ];
    addTearDown(() {
      AppState.I.group = null;
      AppState.I.members = [];
    });
    await _pump(tester, const RecordContributionScreen(meetingId: 'mt1'));
    expect(find.byKey(const ValueKey('savings-kind')), findsOneWidget);
    var field = tester.widget<TextField>(find.byKey(const ValueKey('contribution-amount')));
    expect(field.readOnly, isTrue);
    expect(field.controller!.text, '5000');

    await tester.tap(find.text('Hiari'));
    await tester.pumpAndSettle();
    field = tester.widget<TextField>(find.byKey(const ValueKey('contribution-amount')));
    expect(field.readOnly, isFalse);
    expect(field.controller!.text, '');

    // Only one kind on: no choice shown.
    AppState.I.group = {'id': null, 'mandatorySavingsAmount': 5000, 'enabledServices': ['Voluntary Savings']};
    await _pump(tester, const RecordContributionScreen(meetingId: 'mt2'));
    expect(find.byKey(const ValueKey('savings-kind')), findsNothing);
    expect(find.text('Akiba ya hiari'), findsOneWidget);
  });
}
