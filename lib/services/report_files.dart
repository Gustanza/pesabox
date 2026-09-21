import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../i18n/i18n.dart';
import 'report_data.dart';

/// Most rows one dataset may contribute to a file, so a huge history cannot
/// freeze the app while the file is built.
const int kMaxReportRows = 20000;
const int _maxPdfRows = 5000;

/// One dataset ready to write: the columns the user kept and its rows.
class ExportSet {
  const ExportSet({required this.def, required this.columns, required this.rows});

  final ReportDef def;
  final List<String> columns;
  final List<Map<String, Object?>> rows;

  String get title => I18n.isSwahili ? def.sw : def.en;
}

// ---- CSV -------------------------------------------------------------------

String _csvEscape(String s) =>
    RegExp(r'[",\r\n]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;

/// UTF-8 with a BOM so Excel opens Swahili text correctly.
List<int> buildCsv(ExportSet s) {
  final b = StringBuffer('﻿');
  b.writeln(s.columns.map((c) => _csvEscape(columnLabel(c))).join(','));
  for (final row in s.rows) {
    b.writeln(s.columns.map((c) => _csvEscape(cellText(c, row[c]))).join(','));
  }
  return utf8.encode(b.toString());
}

/// Several datasets as one .zip of CSV files.
List<int> buildCsvZip(List<ExportSet> sets) {
  final archive = Archive();
  for (final s in sets) {
    final bytes = buildCsv(s);
    archive.addFile(ArchiveFile('${s.def.key}.csv', bytes.length, bytes));
  }
  return ZipEncoder().encode(archive)!;
}

// ---- Excel -----------------------------------------------------------------

String _sheetName(String title, Set<String> used) {
  var name = title.replaceAll(RegExp(r'[:\\/?*\[\]]'), ' ').trim();
  if (name.isEmpty) name = 'Sheet';
  if (name.length > 31) name = name.substring(0, 31);
  var candidate = name;
  for (var i = 2; used.contains(candidate); i++) {
    final suffix = ' $i';
    candidate = name.substring(0, name.length.clamp(0, 31 - suffix.length)) + suffix;
  }
  used.add(candidate);
  return candidate;
}

/// One workbook, one sheet per dataset. Numbers stay numeric so the sheet can
/// be summed and sorted.
List<int> buildXlsx(List<ExportSet> sets) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  final used = <String>{};
  final header = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('#0F6E56'),
  );

  for (var i = 0; i < sets.length; i++) {
    final s = sets[i];
    final name = _sheetName(s.title, used);
    if (i == 0 && defaultSheet != null) excel.rename(defaultSheet, name);
    final sheet = excel[name];

    sheet.appendRow([for (final c in s.columns) TextCellValue(columnLabel(c))]);
    for (var c = 0; c < s.columns.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = header;
      sheet.setColumnWidth(c, 20);
    }
    for (final row in s.rows) {
      sheet.appendRow([
        for (final c in s.columns)
          () {
            final v = row[c];
            if (v is int) return IntCellValue(v) as CellValue;
            if (v is double) return DoubleCellValue(v);
            return TextCellValue(cellText(c, v));
          }(),
      ]);
    }
  }
  return excel.encode() ?? const <int>[];
}

// ---- PDF -------------------------------------------------------------------

/// The built-in PDF fonts only cover Latin-1; swap the few symbols the app
/// prints for plain look-alikes instead of showing empty boxes.
String _pdfSafe(String s) {
  const swaps = {'—': '-', '–': '-', '→': '->', '…': '...', '’': "'", '‘': "'", '“': '"', '”': '"', '≈': '~'};
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    if (swaps.containsKey(ch)) {
      b.write(swaps[ch]);
    } else {
      b.write(r <= 0xFF ? ch : '?');
    }
  }
  return b.toString();
}

/// One document, a titled table per dataset.
Future<List<int>> buildPdf(
  List<ExportSet> sets, {
  required String groupName,
  required String period,
}) async {
  final green = PdfColor.fromHex('#0F6E56');
  final doc = pw.Document();
  final sw = I18n.isSwahili;
  final noData = sw ? 'Hakuna data kwa vigezo hivi.' : 'No data for these filters.';

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.center,
        child: pw.Text(
          'PesaBox  |  ${sw ? 'Ukurasa' : 'Page'} ${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
      build: (ctx) => [
        pw.Text(
          _pdfSafe(sw ? 'Ripoti ya PesaBox' : 'PesaBox Report'),
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: green),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _pdfSafe(
            '${sw ? 'Kikundi' : 'Group'}: $groupName    '
            '${sw ? 'Kipindi' : 'Period'}: $period    '
            '${sw ? 'Imetengenezwa' : 'Generated'}: ${DateTime.now().toString().substring(0, 16)}',
          ),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 12),
        for (final s in sets) ...[
          pw.Text(
            _pdfSafe('${s.title} (${s.rows.length})'),
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: green),
          ),
          pw.SizedBox(height: 6),
          if (s.rows.isEmpty)
            pw.Text(noData, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: [for (final c in s.columns) _pdfSafe(columnLabel(c))],
              data: [
                for (final row in s.rows.take(_maxPdfRows))
                  [for (final c in s.columns) _pdfSafe(cellText(c, row[c]))],
              ],
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: green),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0F6F4)),
              cellAlignments: {
                for (var i = 0; i < s.columns.length; i++)
                  i: (s.rows.first[s.columns[i]] is num) ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
              },
            ),
          pw.SizedBox(height: 16),
        ],
      ],
    ),
  );
  return doc.save();
}
