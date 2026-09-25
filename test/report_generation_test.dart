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
  @override
  Future<List<Map<String, dynamic>>> govLoans() async => [];
}

/// A group with a cancelled loan, a reversed transaction and a government
/// loan: the cases the reports must not get wrong.
class _TrickySource extends _FakeSource {
  @override
  Future<List<Map<String, dynamic>>> loans() async => [
        {'loanNumber': 'LN-0001', 'memberName': 'John Mfinanga', 'amount': 50000, 'amountRepaid': 10000, 'status': 'active', 'issuedDate': '2026-08-01T08:00:00Z'},
        {'loanNumber': 'LN-0002', 'memberName': 'Asha Juma', 'amount': 20000, 'amountRepaid': 0, 'status': 'cancelled', 'issuedDate': '2026-09-10T08:00:00Z'},
        {'loanNumber': 'LN-0003', 'memberName': 'Asha Juma', 'amount': 8000, 'amountRepaid': 3000, 'status': 'defaulted', 'issuedDate': '2026-05-01T08:00:00Z'},
      ];

  @override
  Future<List<Map<String, dynamic>>> members() async => [
        ...await super.members(),
        {'firstName': 'Bakari', 'lastName': 'Said', 'status': 'Suspended', 'joinedAt': '2026-01-01T08:00:00Z'},
      ];

  @override
  Future<List<Map<String, dynamic>>> govLoans() async => [
        {'lender': 'Halmashauri', 'amount': 1000000, 'amountRepaid': 250000, 'totalDue': 1100000, 'outstanding': 850000, 'receivedDate': '2026-09-01T07:00:00Z', 'status': 'active'},
      ];
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
    expect(text, contains('Asha Juma,Akiba ya Lazima,5000,Ndani,Taslimu'));
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
    // Loan #, Borrower, Principal, Interest, Total Due, Repaid, Balance: a loan
    // from before interest was charged owes its principal (50000 - 10000).
    final balance = loans.rows[1][6]!.value;
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

  test('cancelled loans owe nothing and stay out of the totals; reversed rows are skipped', () async {
    final src = _TrickySource();
    final loans = await reportDefFor('loans')!.rows(src, const ReportRange());
    final cancelled = loans.firstWhere((r) => r['Loan #'] == 'LN-0002');
    expect(cancelled['Balance'], 0);
    expect(cancelled['Repaid'], 0); // the real repaid amount, not the principal
    expect(cancelled[kNoTotals], isTrue);
    expect(loans.firstWhere((r) => r['Loan #'] == 'LN-0003')['Balance'], 5000); // defaulted still owes

    final f = GroupFigures.compute(
      transactions: await src.transactions(),
      loans: await src.loans(),
      members: await src.members(),
      govLoans: await src.govLoans(),
    );
    expect(f.loansDisbursed, 58000); // 50000 + 8000; the cancelled 20000 was never lent
    expect(f.loansOutstanding, 45000);
    expect(f.savings, 15000); // the reversed 999 is not counted
    expect(f.membersActive, 2);
    expect(f.membersTotal, 3);
    expect(f.govOutstanding, 850000);

    final summary = (await reportDefFor('group-summary')!.rows(src, const ReportRange())).single;
    expect(summary['Loans Outstanding'], 45000);
    expect(summary['Savings'], 15000);
    expect(summary['Government Loans'], 850000);
    expect(summary['Members (active)'], 2);
  });

  test('dates are East Africa Time days, whatever the phone zone', () async {
    // 2026-09-16 22:00 UTC is 2026-09-17 01:00 in Dar es Salaam.
    expect(eatDay('2026-09-16T22:00:00Z'), '2026-09-17');
    expect(eatDay('2026-09-17'), '2026-09-17');
    expect(cellText('Date', '2026-09-16T22:00:00Z'), '2026-09-17');
    final day = ReportRange(from: DateTime(2026, 9, 17), to: DateTime(2026, 9, 17));
    expect(day.contains('2026-09-16T22:00:00Z'), isTrue);
    expect(day.contains('2026-09-17T21:30:00Z'), isFalse); // 00:30 on the 18th
    expect(day.contains(null), isFalse); // no date cannot be placed in a period
    expect(const ReportRange().contains(null), isTrue);
  });

  test('only enum columns are translated', () {
    expect(cellText('Method', 'Cash'), 'Taslimu');
    expect(cellText('Member', 'Active'), 'Active'); // a name is never translated
  });
}
