import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_box_app/i18n/i18n.dart';
import 'package:pesa_box_app/screens/reports/export_report_screen.dart';
import 'package:pesa_box_app/services/report_service.dart';

class _FakeService implements ReportService {
  List<String>? exportedDatasets;
  Map<String, List<String>>? exportedColumns;
  String? exportedFormat;
  bool saved = false;

  @override
  Future<List<ReportDataset>> datasets() async => const [
        ReportDataset(
          key: 'members',
          category: 'Operations',
          categorySw: 'Uendeshaji',
          sw: 'Wanachama',
          en: 'Members',
          columns: [
            ReportColumn(key: 'Name', sw: 'Jina', en: 'Name'),
            ReportColumn(key: 'Phone', sw: 'Simu', en: 'Phone'),
          ],
        ),
        ReportDataset(
          key: 'loans',
          category: 'Financial',
          categorySw: 'Fedha',
          sw: 'Mikopo',
          en: 'Loans',
          columns: [ReportColumn(key: 'Balance', sw: 'Salio', en: 'Balance')],
        ),
      ];

  @override
  Future<ExportedReport> export({
    required List<String> datasets,
    required Map<String, List<String>> columns,
    required String format,
    String from = '',
    String to = '',
  }) async {
    exportedDatasets = datasets;
    exportedColumns = columns;
    exportedFormat = format;
    return const ExportedReport(bytes: [1, 2, 3], filename: 'r.xlsx');
  }

  @override
  Future<String> saveAndOpen(ExportedReport report) async {
    saved = true;
    return '/tmp/${report.filename}';
  }
}

Future<void> _pump(WidgetTester tester, _FakeService svc) async {
  await tester.binding.setSurfaceSize(const Size(420, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: ExportReportScreen(service: svc)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => I18n.locale.value = 'sw');
  tearDown(() => I18n.locale.value = 'sw');

  testWidgets('lists datasets in Swahili and disables export until one is chosen',
      (tester) async {
    await _pump(tester, _FakeService());

    expect(find.text('Wanachama'), findsOneWidget);
    expect(find.text('Mikopo'), findsOneWidget);
    expect(find.text('Pakua data 0'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('exports only the chosen datasets and columns', (tester) async {
    final svc = _FakeService();
    await _pump(tester, svc);

    await tester.tap(find.text('Wanachama')); // tick Members
    await tester.pump();
    expect(find.text('Pakua data 1'), findsOneWidget);

    await tester.tap(find.text('Safu').first); // open its column list
    await tester.pump();
    await tester.tap(find.text('Simu')); // untick Phone
    await tester.pump();

    await tester.tap(find.text('PDF'));
    await tester.pump();
    await tester.tap(find.text('Pakua data 1'));
    await tester.pumpAndSettle();

    expect(svc.exportedDatasets, ['members']);
    expect(svc.exportedColumns, {'members': ['Name']});
    expect(svc.exportedFormat, 'pdf');
    expect(svc.saved, isTrue);
  });

  testWidgets('shows English when the app is in English', (tester) async {
    I18n.locale.value = 'en';
    await _pump(tester, _FakeService());
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Export 0 dataset(s)'), findsOneWidget);
  });
}
