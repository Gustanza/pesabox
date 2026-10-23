import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pesa_box_app/i18n/i18n.dart';
import 'package:pesa_box_app/models/models.dart';
import 'package:pesa_box_app/screens/funds/social_fund_payout_screen.dart';
import 'package:pesa_box_app/screens/meetings/close_cycle_screen.dart';
import 'package:pesa_box_app/services/app_data.dart';
import 'package:pesa_box_app/services/share_out.dart';

Map<String, dynamic> tx(String type, num amount, {String? member, bool reversed = false, Map<String, dynamic> extra = const {}}) =>
    {'type': type, 'amount': amount, 'memberId': member, 'reversed': reversed, ...extra};

// Asha: 10,000 savings + 10,000 shares; Juma: 5,000 savings. Social fund
// 4,000. A 10,000 loan was repaid with 1,000 interest; 1,000 in fines.
final _txns = [
  tx('contribution', 10000, member: 'a'),
  tx('share', 10000, member: 'a'),
  tx('contribution', 5000, member: 'j'),
  tx('contribution', 7000, member: 'j', reversed: true), // ignored
  tx('social_fund', 4000, member: 'a'),
  tx('loan_disbursement', 10000, member: 'j'),
  tx('loan_repayment', 11000, member: 'j'),
  tx('fine', 1000, member: 'j'),
];
final _members = [
  {'id': 'a', 'fullName': 'Asha Juma', 'status': 'Active'},
  {'id': 'j', 'fullName': 'Juma Ali', 'status': 'Active'},
];

void main() {
  setUp(() => I18n.locale.value = 'sw');
  tearDown(() => I18n.locale.value = 'sw');

  test('cash box and social fund follow the server rules (reversed rows skipped)', () {
    final box = groupCash(_txns);
    expect(box.cash, 31000); // 10+10+5+4+11+1 in, 10 out
    expect(box.socialFund, 4000);
    final payout = groupCash([..._txns, tx('social_fund_payout', 1500)]);
    expect(payout.socialFund, 2500);
    expect(payout.cash, 29500);
  });

  test('government loans: only repayments beyond what was received leave the box', () {
    // Received 100,000, repaid 60,000: the rest is still owed, cash unchanged.
    expect(groupCash(_txns, govLoans: [
      {'amount': 100000, 'repayments': [{'amount': 60000}]},
    ]).cash, 31000);
    // Repaid 110,000 of 100,000 (interest): 10,000 left the box.
    expect(groupCash(_txns, govLoans: [
      {'amount': 100000, 'repayments': [{'amount': 60000}, {'amount': 50000}]},
    ]).cash, 21000);
    // Without the repayment list, amountRepaid is used.
    expect(groupCash(_txns, govLoans: [
      {'amount': 1000, 'amountRepaid': 3000},
    ]).cash, 29000);
  });

  test("a member's pool drops by what earlier share-outs returned", () {
    expect(memberPool(_txns, 'a'), (savings: 10000.0, shares: 10000.0));
    final after = [
      ..._txns,
      tx('share_out', 12000, member: 'a', extra: {'savingsReturned': 10000, 'sharesReturned': 2000}),
    ];
    expect(memberPool(after, 'a'), (savings: 0.0, shares: 8000.0));
  });

  test('suggested payout = own money + pro-rata profit, never more than available', () {
    final plan = planShareOut(transactions: _txns, members: _members);
    expect(plan.available, 27000); // 31,000 cash − 4,000 social fund
    expect(plan.poolTotal, 25000);
    expect(plan.profit, 2000);
    final byId = {for (final l in plan.lines) l.memberId: l.suggested};
    expect(byId['a'], 21600); // 20,000 + 2,000 × 20/25
    expect(byId['j'], 5400); // 5,000 + 2,000 × 5/25
    expect(plan.suggestedTotal, lessThanOrEqualTo(plan.available));
    final ent = {for (final l in plan.lines) l.memberId: l.entitlement};
    expect(ent['a'], 21600);
    expect(ent['j'], 5400);
    final juma = plan.lines.firstWhere((l) => l.memberId == 'j');
    expect(juma.exceeds(5401), isFalse); // server allows 1 TZS over
    expect(juma.exceeds(5402), isTrue);
  });

  test('with loans still out, everyone gets the same fraction of their money', () {
    final plan = planShareOut(
      transactions: [..._txns, tx('loan_disbursement', 13500, member: 'j')],
      members: _members,
    );
    expect(plan.available, 13500);
    expect(plan.profit, 0);
    final byId = {for (final l in plan.lines) l.memberId: l.suggested};
    expect(byId['a'], 10800);
    expect(byId['j'], 2700);
    // No profit: the entitlement is the member's own pool.
    final ent = {for (final l in plan.lines) l.memberId: l.entitlement};
    expect(ent['a'], 20000);
    expect(ent['j'], 5000);
  });

  test('cycle 0 (never closed) shows as cycle 1', () {
    expect(currentCycle({'cycleCurrent': 0}), 1);
    expect(currentCycle({'cycleCurrent': 3}), 3);
    expect(currentCycle(null), 1);
  });

  test("logging out or in as someone else drops the previous group's cached data", () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState.I;
    await s.setSession({'id': 'u1'}, 't1', 'r1');
    s.transactions = List.of(_txns);
    s.loans = [{'id': 'l1'}];
    s.memberBalances = List.of(_members);
    await s.setSession({'id': 'u1'}, 't1b', 'r1b');
    expect(s.transactions, isNotEmpty); // same account (token refresh): kept
    await s.setSession({'id': 'u2'}, 't2', 'r2');
    expect(s.transactions, isEmpty);
    expect(s.loans, isEmpty);
    expect(s.memberBalances, isEmpty);
    s.meetings = [{'id': 'm1'}];
    await s.signOut();
    expect(s.meetings, isEmpty);
    expect(s.isSignedIn, isFalse);
  });

  test('member status from the server is read case-insensitively', () {
    expect(Member.fromApi({'id': '1', 'status': 'Inactive'}).status, MemberStatus.inactive);
    expect(Member.fromApi({'id': '1', 'status': 'Suspended'}).status, MemberStatus.suspended);
    expect(Member.fromApi({'id': '1', 'status': 'Active'}).status, MemberStatus.active);
  });

  group('screens', () {
    setUp(() {
      AppState.I.group = {'id': null, 'name': 'Test', 'cycleCurrent': 0, 'totalLoans': 0};
      AppState.I.transactions = List.of(_txns);
      AppState.I.memberBalances = List.of(_members);
      AppState.I.members = [
        {'id': 'a', 'firstName': 'Asha', 'lastName': 'Juma', 'status': 'Active'},
      ];
    });
    tearDown(() {
      AppState.I.group = null;
      AppState.I.transactions = [];
      AppState.I.memberBalances = [];
      AppState.I.members = [];
      AppState.I.groupPermissions = {};
    });

    Future<void> pump(WidgetTester tester, Widget screen) async {
      await tester.binding.setSurfaceSize(const Size(430, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();
    }

    testWidgets('share-out prefills suggestions; close cycle needs group.settings', (tester) async {
      AppState.I.groupPermissions = {'finance.write'};
      await pump(tester, const CloseCycleScreen());
      expect(find.text('Mzunguko 1'), findsOneWidget);
      expect(find.widgetWithText(TextField, '21600'), findsOneWidget);
      expect(find.widgetWithText(TextField, '5400'), findsOneWidget);
      expect(find.text('Lipa TZS 27,000'), findsOneWidget);
      expect(find.byKey(const ValueKey('shareout-close-cycle')), findsNothing);

      // Too much: refused before calling the server.
      await tester.enterText(find.byKey(const ValueKey('payout-j')), '9000');
      await tester.pump();
      expect(find.text('Inazidi fedha zilizopo za kugawa.'), findsOneWidget);
      // 9,000 is above Juma's entitlement (5,000 + 2,000 × 5/25 = 5,400).
      expect(find.byKey(const ValueKey('over-j')), findsOneWidget);
      expect(find.text('Zaidi ya stahili ya mwanachama huyu (TZS 5,400)'), findsOneWidget);
      expect(find.byKey(const ValueKey('over-a')), findsNothing);
    });

    testWidgets('a group admin can also close the cycle', (tester) async {
      AppState.I.groupPermissions = {'finance.write', 'group.settings'};
      await pump(tester, const CloseCycleScreen());
      expect(find.text('Pia funga mzunguko 1 na anza mzunguko 2'), findsOneWidget);
    });

    testWidgets('social fund payout cannot exceed the fund', (tester) async {
      await pump(tester, const SocialFundPayoutScreen());
      expect(find.text('TZS 4,000'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('payout-amount')), '5000');
      await tester.enterText(find.byKey(const ValueKey('payout-reason')), 'Hospitali');
      await tester.tap(find.text('Rekodi malipo'));
      await tester.pumpAndSettle();
      expect(find.text('Mfuko wa jamii una TZS 4,000 tu'), findsOneWidget);
    });
  });
}
