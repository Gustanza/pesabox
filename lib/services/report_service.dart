import '../i18n/i18n.dart';
import 'file_saver.dart';
import 'graphql_client.dart';
import 'report_data.dart';
import 'report_files.dart';

/// One column of a report dataset.
class ReportColumn {
  const ReportColumn({required this.key, required this.sw, required this.en});

  /// Stable id (English column name).
  final String key;
  final String sw;
  final String en;

  String get label => I18n.isSwahili ? sw : en;
}

/// A dataset the user can pick for export (e.g. Members, Loans, Transactions).
class ReportDataset {
  const ReportDataset({
    required this.key,
    required this.category,
    required this.categorySw,
    required this.sw,
    required this.en,
    required this.columns,
  });

  final String key;
  final String category;
  final String categorySw;
  final String sw;
  final String en;
  final List<ReportColumn> columns;

  String get label => I18n.isSwahili ? sw : en;
  String get categoryLabel => I18n.isSwahili ? categorySw : category;
}

/// A file that has been built but not yet saved.
class ExportedReport {
  const ExportedReport({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;
}

/// Builds report files. An interface so screens can be tested with a fake.
abstract class ReportService {
  Future<List<ReportDataset>> datasets();

  /// [columns] maps a dataset key to the column keys to keep; a dataset that
  /// is missing from it keeps every column. [from]/[to] are `YYYY-MM-DD` or
  /// empty (open ended).
  Future<ExportedReport> export({
    required List<String> datasets,
    required Map<String, List<String>> columns,
    required String format,
    String from = '',
    String to = '',
  });

  /// Saves the file (a download in the browser, a file on the device
  /// elsewhere) and returns where it went.
  Future<String> saveAndOpen(ExportedReport report);
}

/// Generates the reports on the device from the data the app already loads —
/// no report endpoint is needed on the server, so it works against any
/// backend the app can log in to.
class LocalReportService implements ReportService {
  LocalReportService({ReportSource? source}) : _source = source ?? const AppStateReportSource();

  final ReportSource _source;

  @override
  Future<List<ReportDataset>> datasets() async => [
        for (final d in kReportDefs)
          ReportDataset(
            key: d.key,
            category: d.category,
            categorySw: categorySw[d.category] ?? d.category,
            sw: d.sw,
            en: d.en,
            columns: [
              for (final c in d.columns)
                ReportColumn(key: c, sw: columnSw[c] ?? c, en: c),
            ],
          ),
      ];

  static DateTime? _parse(String s) => s.isEmpty ? null : DateTime.tryParse(s);

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Future<ExportedReport> export({
    required List<String> datasets,
    required Map<String, List<String>> columns,
    required String format,
    String from = '',
    String to = '',
  }) async {
    if (datasets.isEmpty) {
      throw GraphQLException(tr('Choose at least one dataset to export'));
    }
    if (!const ['pdf', 'xlsx', 'csv'].contains(format)) {
      throw GraphQLException('format must be pdf, xlsx or csv');
    }

    final range = ReportRange(from: _parse(from), to: _parse(to));
    final sets = <ExportSet>[];
    try {
      for (final key in datasets) {
        final def = reportDefFor(key);
        if (def == null) throw GraphQLException('unknown dataset: $key');

        var cols = def.columns;
        final picked = columns[key];
        if (picked != null && picked.isNotEmpty) {
          cols = [for (final c in def.columns) if (picked.contains(c)) c];
          if (cols.isEmpty) {
            throw GraphQLException(tr('Choose at least one column for {0}', [I18n.isSwahili ? def.sw : def.en]));
          }
        }
        var rows = await def.rows(_source, range);
        if (rows.length > kMaxReportRows) rows = rows.sublist(0, kMaxReportRows);
        sets.add(ExportSet(def: def, columns: cols, rows: rows));
      }
    } on GraphQLException {
      rethrow;
    } catch (e) {
      throw GraphQLException(tr('Could not load the data for the report: {0}', ['$e']));
    }

    final List<int> bytes;
    var ext = format;
    switch (format) {
      case 'xlsx':
        bytes = buildXlsx(sets);
      case 'csv':
        if (sets.length == 1) {
          bytes = buildCsv(sets.first);
        } else {
          bytes = buildCsvZip(sets);
          ext = 'zip';
        }
      default:
        final group = (await _source.group())?['name'];
        final period = (from.isEmpty && to.isEmpty)
            ? (I18n.isSwahili ? 'Muda wote' : 'All time')
            : '${from.isEmpty ? '...' : from} - ${to.isEmpty ? '...' : to}';
        bytes = await buildPdf(
          sets,
          groupName: (group == null || '$group'.isEmpty) ? 'PesaBox' : '$group',
          period: period,
        );
    }

    final now = DateTime.now();
    final stamp = '${now.year}${_two(now.month)}${_two(now.day)}-${_two(now.hour)}${_two(now.minute)}';
    return ExportedReport(bytes: bytes, filename: 'pesabox-report-$stamp.$ext');
  }

  @override
  Future<String> saveAndOpen(ExportedReport report) =>
      saveReportFile(report.filename, report.bytes);
}
