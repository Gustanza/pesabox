import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_box_app/i18n/i18n.dart';
import 'package:pesa_box_app/screens/reports/group_statement_screen.dart';
import 'package:pesa_box_app/screens/reports/report_view_screen.dart';
import 'package:pesa_box_app/services/report_data.dart';
import 'package:pesa_box_app/services/report_service.dart';

class _Source implements ReportSource {
  @override
  Future<Map<String, dynamic>?> group() async => {'name': 'Umoja Group', 'totalSavings': 15000, 'totalShares': 3000};
  @override
  Future<List<Map<String, dynamic>>> members() async => [
        {'firstName': 'Asha', 'lastName': 'Juma', 'phone': '0755123456', 'status': 'Active'},
      ];
  @override
  Future<List<Map<String, dynamic>>> transactions() async => [
        {'type': 'contribution', 'amount': 5000, 'direction': 'in', 'memberName': 'Asha Juma', 'createdAt': '2026-09-01T08:00:00Z'},
        {'type': 'contribution', 'amount': 10000, 'direction': 'in', 'memberName': 'John Mfinanga', 'createdAt': '2026-09-15T08:00:00Z'},
        {'type': 'expense', 'amount': 2500, 'direction': 'out', 'memberName': '', 'createdAt': '2026-09-10T08:00:00Z'},
      ];
  @override
  Future<List<Map<String, dynamic>>> loans() async => [];
  @override
  Future<List<Map<String, dynamic>>> fines() async => [];
  @override
  Future<List<Map<String, dynamic>>> meetings() async => [];
  @override
  Future<List<Map<String, dynamic>>> smsActivity() async => [];
  @override
  Future<List<Map<String, dynamic>>> govLoans() async => [];
}

/// A source whose server calls fail.
class _FailingSource extends _Source {
  @override
  Future<List<Map<String, dynamic>>> transactions() async => throw Exception('Request failed (500)');
}

class _RecordingService implements ReportService {
  List<String>? datasets_;
  String? format_;
  bool saved = false;

  @override
  Future<List<ReportDataset>> datasets() async => const [];

  @override
  Future<ExportedReport> export({
    required List<String> datasets,
    required Map<String, List<String>> columns,
    required String format,
    String from = '',
    String to = '',
  }) async {
    datasets_ = datasets;
    format_ = format;
    return const ExportedReport(bytes: [1], filename: 'r.pdf');
  }

  @override
  Future<String> saveAndOpen(ExportedReport report) async {
    saved = true;
    return '/tmp/${report.filename}';
  }
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(430, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => I18n.locale.value = 'sw');
  tearDown(() => I18n.locale.value = 'sw');

  testWidgets('a live report shows the real rows and totals', (tester) async {
    await _pump(tester, ReportViewScreen(defKey: 'savings', source: _Source()));

    expect(find.text('Akiba'), findsWidgets); // title
    expect(find.text('Asha Juma'), findsOneWidget);
    expect(find.text('John Mfinanga'), findsOneWidget);
    expect(find.text('Idadi ya safu'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // two savings rows (the expense is excluded)
    expect(find.text('TZS 15,000'), findsOneWidget); // 5,000 + 10,000
  });

  testWidgets('expenses report only lists expenses', (tester) async {
    await _pump(tester, ReportViewScreen(defKey: 'expenses', source: _Source()));
    expect(find.text('Asha Juma'), findsNothing);
    expect(find.text('TZS 2,500'), findsOneWidget);
  });

  testWidgets('group summary is a list of totals', (tester) async {
    await _pump(tester, ReportViewScreen(defKey: 'group-summary', source: _Source()));
    expect(find.text('Umoja Group'), findsOneWidget);
    expect(find.text('TZS 15,000'), findsOneWidget); // savings, from the transactions
    expect(find.text('TZS 3,000'), findsNothing); // not the stored totalShares
  });

  testWidgets('an empty report says so instead of showing a blank screen', (tester) async {
    await _pump(tester, ReportViewScreen(defKey: 'fines', source: _Source()));
    expect(find.text('Hakuna data kwa vigezo hivi.'), findsOneWidget);
  });

  testWidgets('a failed download shows an error instead of an empty report', (tester) async {
    await _pump(tester, ReportViewScreen(defKey: 'savings', source: _FailingSource()));
    expect(find.textContaining('Request failed (500)'), findsOneWidget);
    expect(find.text('Hakuna data kwa vigezo hivi.'), findsNothing);
  });

  testWidgets('all transactions total money in and money out separately', (tester) async {
    await _pump(tester, ReportViewScreen(defKey: 'transactions', source: _Source()));
    expect(find.text('Pesa iliyoingia'), findsOneWidget);
    expect(find.text('TZS 15,000'), findsOneWidget);
    expect(find.text('Pesa iliyotoka'), findsOneWidget);
    expect(find.text('TZS 2,500'), findsOneWidget);
  });

  testWidgets('the download buttons export exactly this report', (tester) async {
    final svc = _RecordingService();
    await _pump(tester, ReportViewScreen(defKey: 'savings', source: _Source(), service: svc));

    await tester.tap(find.text('Excel'));
    await tester.pumpAndSettle();

    expect(svc.datasets_, ['savings']);
    expect(svc.format_, 'xlsx');
    expect(svc.saved, isTrue);
  });

  testWidgets('group statement shows the group\'s real totals, not sample numbers',
      (tester) async {
    await _pump(tester, GroupStatementScreen(source: _StatementSource()));

    expect(find.text('Umoja Group'), findsOneWidget);
    expect(find.text('MZUNGUKO 2'), findsOneWidget);
    expect(find.text('TZS 1,500,000'), findsOneWidget); // the reversed 700,000 is not added
    expect(find.text('TZS 40,000'), findsNWidgets(2)); // disbursed + outstanding; cancelled loan left out
    expect(find.text('TZS 130,000'), findsNothing);
    expect(find.text('TZS 1,000,000'), findsNWidgets(2)); // government loan received + outstanding
    // the old hard-coded demo numbers must be gone
    expect(find.text('TZS 2,160,000'), findsNothing);
    expect(find.text('Kijiji Savings Group'), findsNothing);
  });

  testWidgets('group statement shows an error with a retry, not stale figures', (tester) async {
    final src = _StatementSource()..fail = true;
    await _pump(tester, GroupStatementScreen(source: src));
    expect(find.textContaining('Request failed (500)'), findsOneWidget);
    expect(find.text('TZS 1,500,000'), findsNothing);

    src.fail = false;
    await tester.tap(find.text('Jaribu tena'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Request failed (500)'), findsNothing);
    expect(find.text('TZS 1,500,000'), findsOneWidget);
  });
}

/// The statement's data; [fail] makes the transactions download fail.
class _StatementSource extends _Source {
  bool fail = false;

  @override
  Future<Map<String, dynamic>?> group() async => {'name': 'Umoja Group', 'shareValue': 5000, 'cycleCurrent': 2, 'cycleTotal': 52};
  @override
  Future<List<Map<String, dynamic>>> transactions() async {
    if (fail) throw Exception('Request failed (500)');
    return [
      {'type': 'contribution', 'amount': 1500000, 'createdAt': '2026-09-01T08:00:00Z'},
      {'type': 'contribution', 'amount': 700000, 'reversed': true, 'createdAt': '2026-09-02T08:00:00Z'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> loans() async => [
        {'amount': 40000, 'amountRepaid': 0, 'status': 'active'},
        {'amount': 90000, 'amountRepaid': 0, 'status': 'cancelled'},
      ];
  @override
  Future<List<Map<String, dynamic>>> govLoans() async => [
        {'amount': 1000000, 'amountRepaid': 0, 'outstanding': 1000000},
      ];
}
