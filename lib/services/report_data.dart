import '../i18n/i18n.dart';
import 'app_data.dart';

/// Where report rows come from. The app implements this with the data it
/// already loads from the server; tests use a fake. Reports are generated on
/// the device from these lists — the server needs no report endpoint.
abstract class ReportSource {
  Future<List<Map<String, dynamic>>> members();
  Future<List<Map<String, dynamic>>> meetings();
  Future<List<Map<String, dynamic>>> transactions();
  Future<List<Map<String, dynamic>>> loans();
  Future<List<Map<String, dynamic>>> fines();
  Future<List<Map<String, dynamic>>> smsActivity();
  Future<Map<String, dynamic>?> group();
}

/// The live app data. `refresh: true` so a report never uses a stale cache.
/// (The signed-in user only receives their own group's data from the server.)
class AppStateReportSource implements ReportSource {
  const AppStateReportSource();

  @override
  Future<List<Map<String, dynamic>>> members() => AppState.I.fetchMembers(refresh: true);
  @override
  Future<List<Map<String, dynamic>>> meetings() => AppState.I.fetchMeetings(refresh: true);
  @override
  Future<List<Map<String, dynamic>>> transactions() => AppState.I.fetchTransactions(refresh: true);
  @override
  Future<List<Map<String, dynamic>>> loans() => AppState.I.fetchLoans(refresh: true);
  @override
  Future<List<Map<String, dynamic>>> fines() => AppState.I.fetchFines(refresh: true);
  @override
  Future<List<Map<String, dynamic>>> smsActivity() => AppState.I.fetchSmsActivity(refresh: true);
  @override
  Future<Map<String, dynamic>?> group() => AppState.I.fetchGroup(refresh: true);
}

/// Inclusive date range; either end may be open.
class ReportRange {
  const ReportRange({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  bool contains(Object? value) {
    if (from == null && to == null) return true;
    final d = DateTime.tryParse('$value');
    if (d == null) return true; // no usable date — don't drop the row
    final day = DateTime(d.year, d.month, d.day);
    if (from != null && day.isBefore(DateTime(from!.year, from!.month, from!.day))) return false;
    if (to != null && day.isAfter(DateTime(to!.year, to!.month, to!.day))) return false;
    return true;
  }
}

/// One selectable dataset: its columns and how to build its rows.
class ReportDef {
  const ReportDef({
    required this.key,
    required this.category,
    required this.sw,
    required this.en,
    required this.columns,
    required this.rows,
  });

  final String key;
  final String category; // Group | Financial | Operations | Communication
  final String sw;
  final String en;
  final List<String> columns; // English column keys, in display order
  final Future<List<Map<String, Object?>>> Function(ReportSource src, ReportRange range) rows;
}

const categorySw = {
  'Group': 'Kikundi',
  'Financial': 'Fedha',
  'Operations': 'Uendeshaji',
  'Communication': 'Mawasiliano',
};

const columnSw = {
  'Group': 'Kikundi', 'Members': 'Wanachama', 'Savings': 'Akiba', 'Shares': 'Hisa',
  'Social Fund': 'Mfuko wa Jamii', 'Loans Out': 'Mikopo Iliyotolewa', 'Fines': 'Faini',
  'Expenses': 'Matumizi', 'Date': 'Tarehe', 'Member': 'Mwanachama', 'Type': 'Aina',
  'Amount': 'Kiasi', 'Direction': 'Mwelekeo', 'Method': 'Njia', 'Reference': 'Kumbukumbu',
  'Loan #': 'Mkopo #', 'Borrower': 'Mkopaji', 'Principal': 'Kiasi cha Mkopo',
  'Repaid': 'Kimelipwa', 'Balance': 'Salio', 'Status': 'Hali', 'Issued': 'Ilitolewa',
  'Due': 'Tarehe ya Kulipa', 'Reason': 'Sababu', 'Paid': 'Kimelipwa', 'Meeting #': 'Mkutano #',
  'Title': 'Kichwa', 'Time': 'Muda', 'Location': 'Mahali', 'Name': 'Jina', 'Phone': 'Simu',
  'Gender': 'Jinsia', 'Member #': 'Namba ya Mwanachama', 'Joined': 'Alijiunga',
  'Recipient': 'Mpokeaji',
};

/// Stored enum-like values (statuses, transaction types...) shown in Swahili.
const valueSw = {
  'Mandatory Savings': 'Akiba ya Lazima', 'Shares': 'Hisa', 'Social Fund': 'Mfuko wa Jamii',
  'Loan Repayment': 'Marejesho ya Mkopo', 'Loan Disbursement': 'Utoaji wa Mkopo',
  'Fine': 'Faini', 'Expense': 'Matumizi', 'Withdrawal': 'Uondoaji', 'Active': 'Hai',
  'Inactive': 'Haifanyi kazi', 'Closed': 'Imefungwa', 'Suspended': 'Amesimamishwa',
  'active': 'Hai', 'repaid': 'Imelipwa', 'defaulted': 'Imeshindwa kulipwa',
  'pending': 'Inasubiri', 'paid': 'Imelipwa', 'waived': 'Imesamehewa',
  'upcoming': 'Inakuja', 'in_progress': 'Inaendelea', 'completed': 'Imekamilika',
  'cancelled': 'Imeghairiwa', 'sent': 'Imetumwa', 'failed': 'Imeshindwa',
  'in': 'Ndani', 'out': 'Nje', 'Male': 'Mwanamume', 'Female': 'Mwanamke',
  'member_otp': 'OTP ya Mwanachama', 'login_otp': 'OTP ya Kuingia',
  'member_joined': 'Amejiunga', 'contribution': 'Akiba ya Lazima', 'share': 'Hisa',
  'social_fund': 'Mfuko wa Jamii', 'loan_disbursement': 'Utoaji wa Mkopo',
  'loan_repayment': 'Marejesho ya Mkopo', 'fine': 'Faini', 'fine_payment': 'Malipo ya Faini',
  'meeting_reminder': 'Kikumbusho cha Mkutano', 'loan_due_soon': 'Mkopo Unakaribia Kuisha',
  'loan_overdue': 'Mkopo Umechelewa', 'other': 'Nyingine',
};

const _dateColumns = {'Date', 'Issued', 'Due', 'Joined'};

String columnLabel(String key) => I18n.isSwahili ? (columnSw[key] ?? key) : key;

/// Text for a cell (CSV / PDF): dates as YYYY-MM-DD, whole numbers without
/// ".00", stored enum values translated.
String cellText(String column, Object? v) {
  if (v == null) return '';
  if (_dateColumns.contains(column)) {
    final s = '$v';
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
  if (v is num) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  }
  final s = '$v';
  return I18n.isSwahili ? (valueSw[s] ?? s) : s;
}

// ---- helpers -------------------------------------------------------------

String _s(Object? v) => v == null ? '' : '$v';
num _n(Object? v) => v is num ? v : (num.tryParse('$v') ?? 0);

String _name(Map<String, dynamic> m) {
  final n = (m['memberName'] ?? m['member'] ?? m['fullName']) as Object?;
  if (n != null && '$n'.trim().isNotEmpty) return '$n'.trim();
  final joined = '${_s(m['firstName'])} ${_s(m['lastName'])}'.trim();
  return joined.isEmpty ? '—' : joined;
}

const _txLabels = {
  'contribution': 'Mandatory Savings', 'share': 'Shares', 'social_fund': 'Social Fund',
  'loan_repayment': 'Loan Repayment', 'loan_disbursement': 'Loan Disbursement',
  'fine': 'Fine', 'expense': 'Expense', 'withdrawal': 'Withdrawal',
};

Future<List<Map<String, Object?>>> _transactionRows(
  ReportSource src,
  ReportRange range, {
  String? type,
}) async {
  final out = <Map<String, Object?>>[];
  for (final t in await src.transactions()) {
    if (t['reversed'] == true) continue;
    if (type != null && _s(t['type']) != type) continue;
    if (!range.contains(t['createdAt'])) continue;
    out.add({
      'Date': t['createdAt'],
      'Member': _name(t),
      'Type': _txLabels[_s(t['type'])] ?? _s(t['type']),
      'Amount': _n(t['amount']),
      'Direction': _s(t['direction']),
      'Method': _s(t['method']),
      'Reference': _s(t['reference']),
    });
  }
  return out;
}

const _txColumns = ['Date', 'Member', 'Type', 'Amount', 'Direction', 'Method', 'Reference'];

/// Every dataset the app can export, in display order.
final List<ReportDef> kReportDefs = [
  ReportDef(
    key: 'group-summary',
    category: 'Group',
    sw: 'Muhtasari wa Kikundi',
    en: 'Group Summary',
    columns: const ['Group', 'Members', 'Savings', 'Shares', 'Social Fund', 'Loans Out', 'Fines', 'Expenses'],
    rows: (src, range) async {
      final g = await src.group() ?? const <String, dynamic>{};
      final members = await src.members();
      return [
        {
          'Group': _s(g['name']),
          'Members': members.length,
          'Savings': _n(g['totalSavings']),
          'Shares': _n(g['totalShares']),
          'Social Fund': _n(g['totalSocialFund']),
          'Loans Out': _n(g['totalLoans']),
          'Fines': _n(g['totalFines']),
          'Expenses': _n(g['totalExpenses']),
        },
      ];
    },
  ),
  ReportDef(
    key: 'savings',
    category: 'Financial',
    sw: 'Akiba',
    en: 'Savings',
    columns: _txColumns,
    rows: (src, range) => _transactionRows(src, range, type: 'contribution'),
  ),
  ReportDef(
    key: 'shares',
    category: 'Financial',
    sw: 'Hisa',
    en: 'Shares',
    columns: _txColumns,
    rows: (src, range) => _transactionRows(src, range, type: 'share'),
  ),
  ReportDef(
    key: 'social-fund',
    category: 'Financial',
    sw: 'Mfuko wa Jamii',
    en: 'Social Fund',
    columns: _txColumns,
    rows: (src, range) => _transactionRows(src, range, type: 'social_fund'),
  ),
  ReportDef(
    key: 'expenses',
    category: 'Financial',
    sw: 'Matumizi',
    en: 'Expenses',
    columns: _txColumns,
    rows: (src, range) => _transactionRows(src, range, type: 'expense'),
  ),
  ReportDef(
    key: 'transactions',
    category: 'Financial',
    sw: 'Miamala Yote',
    en: 'All Transactions',
    columns: _txColumns,
    rows: (src, range) => _transactionRows(src, range),
  ),
  ReportDef(
    key: 'loans',
    category: 'Financial',
    sw: 'Mikopo',
    en: 'Loans',
    columns: const ['Loan #', 'Borrower', 'Principal', 'Repaid', 'Balance', 'Status', 'Issued', 'Due'],
    rows: (src, range) async {
      final out = <Map<String, Object?>>[];
      for (final l in await src.loans()) {
        if (!range.contains(l['issuedDate'])) continue;
        final principal = _n(l['amount']);
        final repaid = _n(l['amountRepaid']);
        out.add({
          'Loan #': _s(l['loanNumber']),
          'Borrower': _name(l),
          'Principal': principal,
          'Repaid': repaid,
          'Balance': principal - repaid,
          'Status': _s(l['status']),
          'Issued': l['issuedDate'],
          'Due': l['dueDate'],
        });
      }
      return out;
    },
  ),
  ReportDef(
    key: 'fines',
    category: 'Financial',
    sw: 'Faini',
    en: 'Fines',
    columns: const ['Date', 'Member', 'Reason', 'Amount', 'Paid', 'Status'],
    rows: (src, range) async {
      final out = <Map<String, Object?>>[];
      for (final f in await src.fines()) {
        if (!range.contains(f['createdAt'])) continue;
        out.add({
          'Date': f['createdAt'],
          'Member': _name(f),
          'Reason': _s(f['reason']),
          'Amount': _n(f['amount']),
          'Paid': _n(f['amountPaid']),
          'Status': _s(f['status']),
        });
      }
      return out;
    },
  ),
  ReportDef(
    key: 'meetings',
    category: 'Operations',
    sw: 'Mikutano',
    en: 'Meetings',
    columns: const ['Meeting #', 'Title', 'Date', 'Time', 'Location', 'Status'],
    rows: (src, range) async {
      final out = <Map<String, Object?>>[];
      for (final m in await src.meetings()) {
        if (!range.contains(m['date'])) continue;
        out.add({
          'Meeting #': _n(m['meetingNumber']),
          'Title': _s(m['title']),
          'Date': m['date'],
          'Time': _s(m['time']),
          'Location': _s(m['location']),
          'Status': _s(m['status']),
        });
      }
      return out;
    },
  ),
  ReportDef(
    key: 'members',
    category: 'Operations',
    sw: 'Wanachama',
    en: 'Members',
    columns: const ['Name', 'Phone', 'Gender', 'Member #', 'Status', 'Joined'],
    rows: (src, range) async => [
      for (final m in await src.members())
        {
          'Name': _name(m),
          'Phone': _s(m['phone']),
          'Gender': _s(m['gender']),
          'Member #': _s(m['memberNumber']),
          'Status': _s(m['status']),
          'Joined': m['joinedAt'],
        },
    ],
  ),
  ReportDef(
    key: 'sms',
    category: 'Communication',
    sw: 'Ujumbe wa SMS',
    en: 'SMS Messages',
    columns: const ['Date', 'Recipient', 'Phone', 'Type', 'Status'],
    rows: (src, range) async {
      final out = <Map<String, Object?>>[];
      for (final s in await src.smsActivity()) {
        final when = s['sentAt'] ?? s['createdAt'];
        if (!range.contains(when)) continue;
        out.add({
          'Date': when,
          'Recipient': _name(s),
          'Phone': _s(s['phone']),
          'Type': _s(s['messageType']),
          'Status': _s(s['status']),
        });
      }
      return out;
    },
  ),
];

ReportDef? reportDefFor(String key) {
  for (final d in kReportDefs) {
    if (d.key == key) return d;
  }
  return null;
}
