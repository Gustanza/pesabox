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
  Future<List<Map<String, dynamic>>> govLoans();
  Future<Map<String, dynamic>?> group();
}

/// The live app data. `refresh: true` so a report never uses a stale cache,
/// and `throwOnError: true` so a failed download is reported as an error
/// instead of silently producing a report from old (or no) data.
/// (The signed-in user only receives their own group's data from the server.)
class AppStateReportSource implements ReportSource {
  const AppStateReportSource();

  @override
  Future<List<Map<String, dynamic>>> members() =>
      AppState.I.fetchMembers(refresh: true, throwOnError: true);
  @override
  Future<List<Map<String, dynamic>>> meetings() =>
      AppState.I.fetchMeetings(refresh: true, throwOnError: true);
  @override
  Future<List<Map<String, dynamic>>> transactions() =>
      AppState.I.fetchTransactions(refresh: true, throwOnError: true);
  @override
  Future<List<Map<String, dynamic>>> loans() =>
      AppState.I.fetchLoans(refresh: true, throwOnError: true);
  @override
  Future<List<Map<String, dynamic>>> fines() =>
      AppState.I.fetchFines(refresh: true, throwOnError: true);
  @override
  Future<List<Map<String, dynamic>>> smsActivity() =>
      AppState.I.fetchSmsActivity(refresh: true, throwOnError: true);
  @override
  Future<List<Map<String, dynamic>>> govLoans() =>
      AppState.I.fetchGovLoans(refresh: true, throwOnError: true);
  @override
  Future<Map<String, dynamic>?> group() =>
      AppState.I.fetchGroup(refresh: true, throwOnError: true);
}

// ---- East Africa Time --------------------------------------------------------

/// Reports use East Africa Time (UTC+3, no daylight saving) whatever time
/// zone the phone is set to. Returns the EAT wall-clock time as a UTC-flagged
/// DateTime (read its year/month/day/hour directly), or null when [value] is
/// not a date. A value without a zone (e.g. a meeting's `2026-09-17`) is
/// already an EAT wall-clock time.
DateTime? toEat(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc().add(const Duration(hours: 3));
  final s = '$value'.trim();
  if (s.isEmpty) return null;
  final d = DateTime.tryParse(s);
  if (d == null) return null;
  if (d.isUtc) return d.add(const Duration(hours: 3));
  return DateTime.utc(d.year, d.month, d.day, d.hour, d.minute, d.second, d.millisecond);
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `YYYY-MM-DD` of [value] in EAT, or null.
String? eatDay(Object? value) {
  final d = toEat(value);
  if (d == null) return null;
  return '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
}

/// Inclusive date range of EAT calendar days; either end may be open.
class ReportRange {
  const ReportRange({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  bool get isOpen => from == null && to == null;

  static int _key(int y, int m, int d) => y * 10000 + m * 100 + d;

  /// A record with no usable date cannot be placed in a period, so it is
  /// left out once a range is set (the same rule as the server's reports).
  bool contains(Object? value) {
    if (isOpen) return true;
    final d = toEat(value);
    if (d == null) return false;
    final day = _key(d.year, d.month, d.day);
    if (from != null && day < _key(from!.year, from!.month, from!.day)) return false;
    if (to != null && day > _key(to!.year, to!.month, to!.day)) return false;
    return true;
  }
}

// ---- Report registry -----------------------------------------------------------

/// One selectable dataset: its columns and how to build its rows.
class ReportDef {
  const ReportDef({
    required this.key,
    required this.category,
    required this.sw,
    required this.en,
    required this.columns,
    required this.rows,
    this.splitByDirection = false,
    this.pointInTime = false,
  });

  final String key;
  final String category; // Group | Financial | Operations | Communication
  final String sw;
  final String en;
  final List<String> columns; // English column keys, in display order
  final Future<List<Map<String, Object?>>> Function(ReportSource src, ReportRange range) rows;

  /// Totals show money in and money out separately (a mixed list of
  /// transactions has no meaningful single sum).
  final bool splitByDirection;

  /// Current balances: the date range does not apply.
  final bool pointInTime;
}

/// Row key that keeps a row out of the on-screen totals (e.g. a cancelled
/// loan). Never shown or exported — only listed columns are.
const kNoTotals = '_noTotals';

const categorySw = {
  'Group': 'Kikundi',
  'Financial': 'Fedha',
  'Operations': 'Uendeshaji',
  'Communication': 'Mawasiliano',
};

const columnSw = {
  'Group': 'Kikundi', 'Members': 'Wanachama', 'Members (active)': 'Wanachama Hai',
  'Members (total)': 'Wanachama Wote', 'Savings': 'Akiba', 'Shares': 'Hisa',
  'Social Fund': 'Mfuko wa Jamii', 'Loans Outstanding': 'Mikopo Inayodaiwa', 'Fines': 'Faini',
  'Fines Collected': 'Faini Zilizolipwa', 'Government Loans': 'Mikopo ya Serikali',
  'Expenses': 'Matumizi', 'Date': 'Tarehe', 'Member': 'Mwanachama', 'Type': 'Aina',
  'Amount': 'Kiasi', 'Direction': 'Mwelekeo', 'Method': 'Njia', 'Reference': 'Kumbukumbu',
  'Loan #': 'Mkopo #', 'Borrower': 'Mkopaji', 'Principal': 'Kiasi cha Mkopo',
  'Repaid': 'Kimelipwa', 'Balance': 'Salio', 'Status': 'Hali', 'Issued': 'Ilitolewa',
  'Due': 'Tarehe ya Kulipa', 'Reason': 'Sababu', 'Paid': 'Imelipwa', 'Meeting #': 'Mkutano #',
  'Title': 'Kichwa', 'Time': 'Muda', 'Location': 'Mahali', 'Name': 'Jina', 'Phone': 'Simu',
  'Gender': 'Jinsia', 'Member #': 'Namba ya Mwanachama', 'Joined': 'Alijiunga',
  'Recipient': 'Mpokeaji', 'Charged': 'Faini Iliyotozwa', 'Outstanding': 'Inayodaiwa',
  'Lender': 'Mkopeshaji', 'Programme': 'Programu', 'Interest %': 'Riba %',
  'Total Due': 'Jumla Inayodaiwa', 'Description': 'Maelezo', 'Interest': 'Riba',
};

/// Stored enum-like values (statuses, transaction types...) shown in Swahili.
/// Only applied to the enum columns in [_enumColumns] — never to names or
/// other free text.
const valueSw = {
  'Mandatory Savings': 'Akiba ya Lazima', 'Shares': 'Hisa', 'Social Fund': 'Mfuko wa Jamii',
  'Loan Repayment': 'Marejesho ya Mkopo', 'Loan Disbursement': 'Utoaji wa Mkopo',
  'Fine': 'Faini', 'Fine Payment': 'Malipo ya Faini', 'Expense': 'Matumizi', 'Withdrawal': 'Uondoaji',
  'Active': 'Hai', 'Inactive': 'Haifanyi kazi', 'Closed': 'Imefungwa', 'Suspended': 'Amesimamishwa',
  'active': 'Hai', 'repaid': 'Imelipwa', 'defaulted': 'Imeshindwa kulipwa',
  'pending': 'Inasubiri', 'paid': 'Imelipwa', 'waived': 'Imesamehewa',
  'upcoming': 'Inakuja', 'in_progress': 'Inaendelea', 'completed': 'Imekamilika',
  'cancelled': 'Imeghairiwa', 'sent': 'Imetumwa', 'failed': 'Imeshindwa',
  'in': 'Ndani', 'out': 'Nje', 'Male': 'Mwanamume', 'Female': 'Mwanamke',
  'Cash': 'Taslimu', 'Mobile Money': 'Pesa kwa Simu', 'Bank Transfer': 'Uhamisho wa Benki',
  'Weekly': 'Kila Wiki', 'Biweekly': 'Kila Wiki Mbili', 'Monthly': 'Kila Mwezi',
  'member_otp': 'OTP ya Mwanachama', 'login_otp': 'OTP ya Kuingia',
  'member_joined': 'Amejiunga', 'contribution': 'Akiba ya Lazima', 'share': 'Hisa',
  'social_fund': 'Mfuko wa Jamii', 'loan_disbursement': 'Utoaji wa Mkopo',
  'loan_repayment': 'Marejesho ya Mkopo', 'fine': 'Faini', 'fine_payment': 'Malipo ya Faini',
  'meeting_reminder': 'Kikumbusho cha Mkutano', 'loan_due_soon': 'Mkopo Unakaribia Kuisha',
  'loan_overdue': 'Mkopo Umechelewa', 'other': 'Nyingine', 'expense': 'Matumizi',
  'withdrawal': 'Uondoaji',
};

const _enumColumns = {'Type', 'Status', 'Direction', 'Gender', 'Method'};
const _dateColumns = {'Date', 'Issued', 'Due', 'Joined'};

String columnLabel(String key) => I18n.isSwahili ? (columnSw[key] ?? key) : key;

/// Text for a cell (CSV / PDF / screen): dates as the EAT day YYYY-MM-DD,
/// whole numbers without ".00", enum values translated.
String cellText(String column, Object? v) {
  if (v == null) return '';
  if (_dateColumns.contains(column)) return eatDay(v) ?? '$v';
  if (v is num) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  }
  final s = '$v';
  if (!_enumColumns.contains(column)) return s;
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
  'fine': 'Fine Payment', 'expense': 'Expense', 'withdrawal': 'Withdrawal',
};

/// The one "active member" rule (same as the server): status Active, or no
/// status (the schema default). Inactive and Suspended members are not active.
bool memberActive(Map<String, dynamic> m) {
  final s = _s(m['status']).trim();
  return s.isEmpty || s.toLowerCase() == 'active';
}

/// A loan still owes money unless it is repaid, completed or cancelled.
bool loanOpen(Map<String, dynamic> l) =>
    !const {'repaid', 'completed', 'cancelled'}.contains(_s(l['status']).toLowerCase());

/// What a loan must repay in total: its stored total due (principal + the
/// flat interest fixed at issue). Loans from before interest was charged have
/// no totalDue and owe the principal only (same rule as the server).
num loanTotalDue(Map<String, dynamic> l) {
  final t = _n(l['totalDue']);
  return t > 0 ? t : _n(l['amount']);
}

/// The interest charged on a loan (0 for older loans).
num loanInterest(Map<String, dynamic> l) {
  final i = loanTotalDue(l) - _n(l['amount']);
  return i < 0 ? 0 : i;
}

/// What a loan still owes (never negative); 0 for a closed or cancelled loan.
num loanBalance(Map<String, dynamic> l) {
  if (!loanOpen(l)) return 0;
  final b = loanTotalDue(l) - _n(l['amountRepaid']);
  return b < 0 ? 0 : b;
}

/// The group's money, computed from its non-reversed transactions and its
/// non-cancelled loans — never from the stored running totals, which can
/// drift. Shared by the Group Summary report and the Group Statement.
class GroupFigures {
  num savings = 0, shares = 0, socialFund = 0, fines = 0, expenses = 0, withdrawals = 0;
  num loansOutstanding = 0, loansDisbursed = 0, loansRepaid = 0;
  num govReceived = 0, govRepaid = 0, govOutstanding = 0;
  int membersActive = 0, membersTotal = 0;

  GroupFigures.compute({
    List<Map<String, dynamic>> transactions = const [],
    List<Map<String, dynamic>> loans = const [],
    List<Map<String, dynamic>> members = const [],
    List<Map<String, dynamic>> govLoans = const [],
  }) {
    for (final t in transactions) {
      if (t['reversed'] == true) continue;
      final a = _n(t['amount']);
      switch (_s(t['type'])) {
        case 'contribution':
          savings += a;
        case 'withdrawal':
          savings -= a;
          withdrawals += a;
        case 'share':
          shares += a;
        case 'social_fund':
          socialFund += a;
        case 'fine':
          fines += a;
        case 'expense':
          expenses += a;
      }
    }
    if (savings < 0) savings = 0;
    for (final l in loans) {
      if (_s(l['status']) == 'cancelled') continue;
      loansDisbursed += _n(l['amount']);
      loansRepaid += _n(l['amountRepaid']);
      loansOutstanding += loanBalance(l);
    }
    for (final m in members) {
      membersTotal++;
      if (memberActive(m)) membersActive++;
    }
    for (final g in govLoans) {
      govReceived += _n(g['amount']);
      govRepaid += _n(g['amountRepaid']);
      final o = g['outstanding'];
      govOutstanding += o is num ? o : 0;
    }
  }
}

Future<List<Map<String, Object?>>> _transactionRows(
  ReportSource src,
  ReportRange range, {
  Set<String>? types,
}) async {
  final out = <Map<String, Object?>>[];
  for (final t in await src.transactions()) {
    if (t['reversed'] == true) continue;
    if (types != null && !types.contains(_s(t['type']))) continue;
    if (!range.contains(t['createdAt'])) continue;
    out.add({
      'Date': t['createdAt'],
      'Member': _name(t),
      'Type': _txLabels[_s(t['type'])] ?? _s(t['type']),
      'Amount': _n(t['amount']),
      'Direction': _s(t['direction']),
      'Method': _s(t['method']),
      'Reference': _s(t['reference']),
      'Description': _s(t['description']),
    });
  }
  _newestFirst(out, 'Date');
  return out;
}

/// Newest first by a date column (rows without a date go last).
void _newestFirst(List<Map<String, Object?>> rows, String column) {
  rows.sort((a, b) {
    final da = toEat(a[column]), db = toEat(b[column]);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  });
}

const _txColumns = ['Date', 'Member', 'Type', 'Amount', 'Direction', 'Method', 'Reference'];

/// Every dataset the app can export, in display order.
final List<ReportDef> kReportDefs = [
  ReportDef(
    key: 'group-summary',
    category: 'Group',
    sw: 'Muhtasari wa Kikundi',
    en: 'Group Summary',
    pointInTime: true,
    columns: const [
      'Group', 'Members (active)', 'Members (total)', 'Savings', 'Shares', 'Social Fund',
      'Fines Collected', 'Expenses', 'Loans Outstanding', 'Government Loans',
    ],
    rows: (src, range) async {
      final g = await src.group() ?? const <String, dynamic>{};
      final f = GroupFigures.compute(
        transactions: await src.transactions(),
        loans: await src.loans(),
        members: await src.members(),
        govLoans: await src.govLoans(),
      );
      return [
        {
          'Group': _s(g['name']),
          'Members (active)': f.membersActive,
          'Members (total)': f.membersTotal,
          'Savings': f.savings,
          'Shares': f.shares,
          'Social Fund': f.socialFund,
          'Fines Collected': f.fines,
          'Expenses': f.expenses,
          'Loans Outstanding': f.loansOutstanding,
          'Government Loans': f.govOutstanding,
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
    rows: (src, range) => _transactionRows(src, range, types: {'contribution'}),
  ),
  ReportDef(
    key: 'shares',
    category: 'Financial',
    sw: 'Hisa',
    en: 'Shares',
    columns: _txColumns,
    rows: (src, range) => _transactionRows(src, range, types: {'share'}),
  ),
  ReportDef(
    key: 'social-fund',
    category: 'Financial',
    sw: 'Mfuko wa Jamii',
    en: 'Social Fund',
    columns: _txColumns,
    rows: (src, range) => _transactionRows(src, range, types: {'social_fund'}),
  ),
  ReportDef(
    key: 'expenses',
    category: 'Financial',
    sw: 'Matumizi na Uondoaji',
    en: 'Expenses & Withdrawals',
    columns: const ['Date', 'Type', 'Description', 'Member', 'Amount', 'Method'],
    rows: (src, range) => _transactionRows(src, range, types: {'expense', 'withdrawal'}),
  ),
  ReportDef(
    key: 'transactions',
    category: 'Financial',
    sw: 'Miamala Yote',
    en: 'All Transactions',
    columns: _txColumns,
    splitByDirection: true,
    rows: (src, range) => _transactionRows(src, range),
  ),
  ReportDef(
    key: 'loans',
    category: 'Financial',
    sw: 'Mikopo',
    en: 'Loans',
    columns: const ['Loan #', 'Borrower', 'Principal', 'Interest', 'Total Due', 'Repaid', 'Balance', 'Status', 'Issued', 'Due'],
    rows: (src, range) async {
      final out = <Map<String, Object?>>[];
      for (final l in await src.loans()) {
        if (!range.contains(l['issuedDate'] ?? l['createdAt'])) continue;
        final cancelled = _s(l['status']) == 'cancelled';
        out.add({
          'Loan #': _s(l['loanNumber']),
          'Borrower': _name(l),
          'Principal': _n(l['amount']),
          'Interest': loanInterest(l),
          'Total Due': loanTotalDue(l),
          'Repaid': _n(l['amountRepaid']), // the real amount, even when cancelled
          'Balance': loanBalance(l), // 0 for a cancelled loan
          'Status': _s(l['status']),
          'Issued': l['issuedDate'] ?? l['createdAt'],
          'Due': l['dueDate'],
          if (cancelled) kNoTotals: true, // a cancelled loan was never lent
        });
      }
      _newestFirst(out, 'Issued');
      return out;
    },
  ),
  ReportDef(
    key: 'fines-outstanding',
    category: 'Financial',
    sw: 'Faini Zilizotozwa na Madeni',
    en: 'Fines Charged & Outstanding',
    columns: const ['Date', 'Member', 'Reason', 'Charged', 'Paid', 'Outstanding', 'Status'],
    rows: (src, range) async {
      final out = <Map<String, Object?>>[];
      for (final f in await src.fines()) {
        final when = f['issuedAt'] ?? f['createdAt'];
        if (!range.contains(when)) continue;
        final charged = _n(f['amount']);
        final paid = _n(f['amountPaid']);
        final waived = _s(f['status']) == 'waived';
        final owed = charged - paid;
        out.add({
          'Date': when,
          'Member': _name(f),
          'Reason': _s(f['reason']),
          'Charged': charged,
          'Paid': paid,
          'Outstanding': waived || owed < 0 ? 0 : owed,
          'Status': _s(f['status']),
        });
      }
      _newestFirst(out, 'Date');
      return out;
    },
  ),
  ReportDef(
    key: 'fines',
    category: 'Financial',
    sw: 'Malipo ya Faini',
    en: 'Fine Payments',
    columns: _txColumns,
    rows: (src, range) => _transactionRows(src, range, types: {'fine'}),
  ),
  ReportDef(
    key: 'government-loans',
    category: 'Financial',
    sw: 'Mikopo ya Serikali',
    en: 'Government Loans',
    columns: const ['Lender', 'Programme', 'Reference', 'Principal', 'Interest %', 'Total Due', 'Repaid', 'Balance', 'Issued', 'Due', 'Status'],
    rows: (src, range) async {
      final out = <Map<String, Object?>>[];
      for (final g in await src.govLoans()) {
        if (!range.contains(g['receivedDate'] ?? g['createdAt'])) continue;
        out.add({
          'Lender': _s(g['lender']),
          'Programme': _s(g['programme']),
          'Reference': _s(g['reference']),
          'Principal': _n(g['amount']),
          'Interest %': _n(g['interestRate']),
          'Total Due': _n(g['totalDue']),
          'Repaid': _n(g['amountRepaid']),
          'Balance': _n(g['outstanding']),
          'Issued': g['receivedDate'] ?? g['createdAt'],
          'Due': g['dueDate'],
          'Status': _s(g['status']),
        });
      }
      _newestFirst(out, 'Issued');
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
        if (!range.contains(m['date'] ?? m['createdAt'])) continue;
        out.add({
          'Meeting #': _n(m['meetingNumber']),
          'Title': _s(m['title']),
          'Date': m['date'] ?? m['createdAt'],
          'Time': _s(m['time']),
          'Location': _s(m['location']),
          'Status': _s(m['status']),
        });
      }
      out.sort((a, b) => (b['Meeting #'] as num).compareTo(a['Meeting #'] as num));
      return out;
    },
  ),
  ReportDef(
    key: 'members',
    category: 'Operations',
    sw: 'Wanachama',
    en: 'Members',
    columns: const ['Name', 'Phone', 'Gender', 'Member #', 'Status', 'Joined'],
    rows: (src, range) async {
      final out = <Map<String, Object?>>[];
      for (final m in await src.members()) {
        if (!range.contains(m['joinedAt'] ?? m['createdAt'])) continue;
        out.add({
          'Name': _name(m),
          'Phone': _s(m['phone']),
          'Gender': _s(m['gender']),
          'Member #': _s(m['memberNumber']),
          'Status': _s(m['status']),
          'Joined': m['joinedAt'] ?? m['createdAt'],
        });
      }
      out.sort((a, b) => '${a['Name']}'.toLowerCase().compareTo('${b['Name']}'.toLowerCase()));
      return out;
    },
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
      _newestFirst(out, 'Date');
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
