import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_box_app/i18n/i18n.dart';
import 'package:pesa_box_app/services/report_data.dart';
import 'package:pesa_box_app/services/report_service.dart';

/// Data the app would normally load from the server.
class _FakeSource implements ReportSource {
  @override
  Future<Map<String, dynamic>?> group() async => {
        'name': 'Umoja Group',
        'totalSavings': 15000,
        'totalShares': 3000,
        'totalSocialFund': 0,
        'totalLoans': 40000,
        'totalFines': 1000,
        'totalExpenses': 0,
      };

  @override
  Future<List<Map<String, dynamic>>> members() async => [
        {'firstName': 'Asha', 'lastName': 'Juma', 'phone': '0755123456', 'gender': 'Female', 'memberNumber': 'M-001', 'status': 'Active', 'joinedAt': '2026-03-01T10:00:00Z'},
        {'firstName': 'John', 'lastName': 'Mfinanga', 'phone': '0712000111', 'gender': 'Male', 'memberNumber': 'M-002', 'status': 'Active', 'joinedAt': '2026-03-05T10:00:00Z'},
      ];

  @override
  Future<List<Map<String, dynamic>>> transactions() async => [
        {'type': 'contribution', 'amount': 5000, 'direction': 'in', 'memberName': 'Asha Juma', 'createdAt': '2026-09-01T08:00:00Z', 'method': 'Cash'},
        {'type': 'contribution', 'amount': 10000, 'direction': 'in', 'memberName': 'John Mfinanga', 'createdAt': '2026-09-15T08:00:00Z', 'method': 'Cash'},
        {'type': 'share', 'amount': 3000, 'direction': 'in', 'memberName': 'Asha Juma', 'createdAt': '2026-09-02T08:00:00Z'},
        {'type': 'contribution', 'amount': 999, 'direction': 'in', 'memberName': 'Reversed', 'createdAt': '2026-09-03T08:00:00Z', 'reversed': true},
      ];

  @override
  Future<List<Map<String, dynamic>>> loans() async => [
        {'loanNumber': 'LN-0001', 'memberName': 'John Mfinanga', 'amount': 50000, 'amountRepaid': 10000, 'status': 'active', 'issuedDate': '2026-08-01', 'dueDate': '2027-02-01'},
      ];

  @override
  Future<List<Map<String, dynamic>>> fines() async => [];
  @override
  Future<List<Map<String, dynamic>>> meetings() async => [];
  @override
  Future<List<Map<String, dynamic>>> smsActivity() async => [];
}

LocalReportService _service() => LocalReportService(source: _FakeSource());

void main() {
  setUp(() => I18n.locale.value = 'sw');
  tearDown(() => I18n.locale.value = 'sw');

  test('the catalog lists the datasets with Swahili labels', () async {
    final ds = await _service().datasets();
    expect(ds.length, greaterThan(8));
    final members = ds.firstWhere((d) => d.key == 'members');
    expect(members.label, 'Wanachama');
    expect(members.columns.first.label, 'Jina');
    I18n.locale.value = 'en';
    expect(members.label, 'Members');
  });

  test('CSV: single dataset, Swahili headers/values, reversed rows skipped', () async {
    final file = await _service().export(datasets: ['savings'], columns: {}, format: 'csv');
    expect(file.filename, endsWith('.csv'));
    final text = utf8.decode(file.bytes);
    // Excel needs the UTF-8 byte-order mark to read Swahili text correctly
    // (utf8.decode hides it, so check the raw bytes).
    expect(file.bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
    expect(text, contains('Tarehe,Mwanachama,Aina,Kiasi,Mwelekeo,Njia,Kumbukumbu'));
    expect(text, contains('Asha Juma,Akiba ya Lazima,5000,Ndani,Cash'));
    expect(text, isNot(contains('Reversed')));
    expect(text, isNot(contains('Hisa'))); // shares are not in the savings dataset
  });

  test('column picker keeps only the chosen columns', () async {
    final file = await _service().export(
      datasets: ['members'],
      columns: {'members': ['Name', 'Phone']},
      format: 'csv',
    );
    final lines = utf8.decode(file.bytes).trim().split('\n');
    expect(lines.first.replaceAll('﻿', ''), 'Jina,Simu');
    expect(lines[1], 'Asha Juma,0755123456');
  });

  test('date range filters rows', () async {
    final file = await _service().export(
      datasets: ['savings'],
      columns: {},
      format: 'csv',
      from: '2026-09-10',
      to: '2026-09-30',
    );
    final text = utf8.decode(file.bytes);
    expect(text, contains('John Mfinanga'));
    expect(text, isNot(contains('Asha Juma')));
  });

  test('several CSV datasets become a zip', () async {
    final file = await _service().export(datasets: ['members', 'loans'], columns: {}, format: 'csv');
    expect(file.filename, endsWith('.zip'));
    final zip = ZipDecoder().decodeBytes(file.bytes);
    expect(zip.files.map((f) => f.name).toSet(), {'members.csv', 'loans.csv'});
  });

  test('Excel: one sheet per dataset, numbers stay numeric', () async {
    final file = await _service().export(datasets: ['loans', 'group-summary'], columns: {}, format: 'xlsx');
    expect(file.filename, endsWith('.xlsx'));
    final book = Excel.decodeBytes(file.bytes);
    expect(book.tables.keys.toList(), ['Mikopo', 'Muhtasari wa Kikundi']);

    final loans = book['Mikopo'];
    expect(loans.rows.first.map((c) => c?.value.toString()).first, 'Mkopo #');
    final balance = loans.rows[1][4]!.value; // Balance = 50000 - 10000
    expect(balance is IntCellValue || balance is DoubleCellValue, isTrue);
    expect(balance.toString(), anyOf('40000', '40000.0'));
  });

  test('PDF is a real document, in both languages', () async {
    for (final lang in ['sw', 'en']) {
      I18n.locale.value = lang;
      final file = await _service().export(datasets: ['members', 'fines'], columns: {}, format: 'pdf');
      expect(file.filename, endsWith('.pdf'));
      expect(utf8.decode(file.bytes.take(5).toList()), '%PDF-');
      expect(file.bytes.length, greaterThan(1500), reason: lang);
    }
  });

  test('empty selection and unknown datasets are rejected', () async {
    await expectLater(_service().export(datasets: [], columns: {}, format: 'pdf'), throwsA(isA<Exception>()));
    await expectLater(_service().export(datasets: ['nope'], columns: {}, format: 'pdf'), throwsA(isA<Exception>()));
    await expectLater(
      _service().export(datasets: ['members'], columns: {'members': ['Bogus']}, format: 'csv'),
      // unknown column names leave nothing to export
      throwsA(isA<Exception>()),
    );
  });
}
