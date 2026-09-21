import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart' hide resolveApiBaseUrl;
import 'graphql_client.dart';
import '../i18n/i18n.dart';

/// Application-wide state: auth session + cached group data fetched from the
/// Go backend. Screens read from here instead of the hardcoded mock file.
///
/// Every fetch fails silently and keeps whatever was cached last, so the UI
/// degrades gracefully when the API is offline.
class AppState {
  AppState._();

  static final AppState instance = AppState._();
  static AppState get I => instance;

  // ---------------------------------------------------------------------------
  // Auth
  //
  // Signup and login are the same thing here: enter a phone number, receive
  // an OTP, verify it. There's no separate "create account" step and no
  // password — the backend creates the account on first successful OTP
  // verification. See services/auth_service.dart.
  // ---------------------------------------------------------------------------

  String? token;
  String? refreshToken;
  Map<String, dynamic>? user;

  bool get isLoggedIn => token != null;
  String get userId => (user?['id'] as String?) ?? '';
  // The backend stores the normalized login identifier under `username`
  // (not `phone` — that field comes back empty for OTP/phone accounts), so
  // `username` is the actual phone number here since this app only ever
  // logs in with a phone.
  String get userPhone =>
      (user?['username'] as String?) ?? (user?['phone'] as String?) ?? '';
  /// A human name for this session — never the raw phone number. OTP-created
  /// accounts have no firstName/lastName, so falling back to `username`
  /// would just print the phone number ("Hello, 255712345678"), which reads
  /// as a bug rather than a greeting. The group's `adminName` ("Responsible
  /// officer") is the closest thing the system has to a real name at this
  /// point, since it was typed in by the Super Admin when assigning this
  /// person their group.
  String get userName {
    final first = (user?['firstName'] as String?) ?? '';
    final last = (user?['lastName'] as String?) ?? '';
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;
    final adminName = group?['adminName'] as String?;
    if (adminName != null && adminName.trim().isNotEmpty) return adminName;
    return 'there';
  }

  String get userRole => (user?['role'] as String?) ?? 'user';

  // ---------------------------------------------------------------------------
  // Session persistence
  //
  // Tokens are stashed in SharedPreferences so a killed/restarted app comes
  // back logged in instead of bouncing to the login screen every time.
  // ---------------------------------------------------------------------------

  static const _kToken = 'session.token';
  static const _kRefreshToken = 'session.refreshToken';
  static const _kUser = 'session.user';

  /// Sets the session after a successful OTP verification and persists it.
  Future<void> setSession(Map<String, dynamic> loggedInUser) async {
    token = loggedInUser['accessToken'] as String?;
    refreshToken = loggedInUser['refreshToken'] as String?;
    user = loggedInUser;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_kToken);
      await prefs.remove(_kRefreshToken);
      await prefs.remove(_kUser);
      return;
    }
    await prefs.setString(_kToken, token!);
    if (refreshToken != null) {
      await prefs.setString(_kRefreshToken, refreshToken!);
    }
    if (user != null) {
      await prefs.setString(_kUser, jsonEncode(user));
    }
  }

  Future<bool>? _refreshing;

  /// Exchanges [refreshToken] for a new access/refresh token pair. The
  /// backend's default access token TTL is just 15 minutes, so this gets
  /// called automatically by [GraphQLClient] and [_restPost] whenever a
  /// request comes back 401 — see their retry-once-after-refresh logic.
  /// Concurrent callers share one in-flight refresh instead of each firing
  /// their own.
  Future<bool> refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final rt = refreshToken;
    if (rt == null || rt.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('${resolveApiBaseUrl()}/refresh'),
        headers: {'Accept': 'application/json', 'X-Refresh-Token': rt},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return false;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return false;
      final newAccess = decoded['accessToken'] as String?;
      if (newAccess == null || newAccess.isEmpty) return false;
      token = newAccess;
      final newRefresh = decoded['refreshToken'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) refreshToken = newRefresh;
      await _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Restores a previously persisted session, if any. Returns true when a
  /// session was found and restored.
  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_kToken);
    if (storedToken == null || storedToken.isEmpty) return false;
    token = storedToken;
    refreshToken = prefs.getString(_kRefreshToken);
    final storedUser = prefs.getString(_kUser);
    if (storedUser != null) {
      try {
        user = Map<String, dynamic>.from(jsonDecode(storedUser) as Map);
      } catch (_) {
        user = null;
      }
    }
    return true;
  }

  Future<void> signOut() async {
    token = null;
    refreshToken = null;
    user = null;
    group = null;
    await _persist();
  }

  /// Whether this session has been assigned a group (i.e. a Super Admin has
  /// created a group and set this user as its admin). Populated by
  /// [checkGroupAssignment].
  bool get hasGroup => group != null;

  /// Last 9 digits of a phone number (drops any leading `0` or country
  /// code), used to match a group's admin phone against the logged-in
  /// user's phone regardless of which format either was typed in — the web
  /// admin's "Responsible officer" field is free text (e.g. `0650980535`)
  /// while the backend normalizes an app login to E.164-ish (`255650980535`).
  static String _phoneTail(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  }

  /// Looks up the group this user administers, if any: either a group whose
  /// `createdBy` points at this user's account, or (more commonly, since a
  /// Super Admin usually assigns a group by phone number before that admin
  /// has ever logged in) a group whose `adminPhone` matches this user's
  /// phone. Caches the result in [group].
  Future<bool> checkGroupAssignment({bool refresh = false}) async {
    if (group != null && !refresh) return true;
    final phoneTail = _phoneTail(userPhone);
    if (userId.isEmpty && phoneTail.isEmpty) return false;
    try {
      final conditions = <Map<String, dynamic>>[];
      if (userId.isNotEmpty) {
        conditions.add({
          'createdBy': {'equalTo': userId},
        });
      }
      if (phoneTail.isNotEmpty) {
        // matchesRegex runs through the backend's fuzzy-search helper, which
        // escapes regex metacharacters and applies no anchors — so this is
        // effectively a substring ("contains") match, which is what we want
        // here since phoneTail is just the last 9 digits.
        conditions.add({
          'adminPhone': {'matchesRegex': phoneTail},
        });
      }
      final data = await gql.query(
        r'''
          query($where: WhereGroupInput){
            groups(where: $where) {
              id name region district ward village
              memberCount femaleMembers maleMembers youthMembers
              meetingFrequency adminName adminPhone status
              cycleCurrent cycleTotal
              shareValue minShares maxShares socialFundContribution
              mandatorySavingsAmount loanInterestRate maxLoanPeriodMonths
              lateMeetingFine absenceFine lateLoanRepaymentFine fineReasons
              totalSavings totalShares totalSocialFund totalLoans
              totalFines totalExpenses savingsModel enabledServices
            }
          }
        ''',
        {
          'where': {'OR': conditions},
        },
      );
      final groups = (data['groups'] as List?) ?? const [];
      if (groups.isEmpty) {
        group = null;
        return false;
      }
      group = Map<String, dynamic>.from(groups.first as Map);
      return true;
    } catch (_) {
      // Keep whatever was cached; don't flip an assigned group back to
      // "awaiting" just because a single request failed.
      return group != null;
    }
  }

  // ---------------------------------------------------------------------------
  // Cache
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? group;
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> meetings = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> loans = [];
  List<Map<String, dynamic>> fines = [];
  List<Map<String, dynamic>> announcements = [];
  List<Map<String, dynamic>> smsActivity = [];

  Map<String, dynamic>? _memberById(String? id) {
    if (id == null) return null;
    for (final m in members) {
      if (m['id'] == id) return m;
    }
    return null;
  }

  /// Looks up a member by id, refreshing the member list once if it isn't
  /// cached yet.
  Future<Map<String, dynamic>?> memberById(String? id) async {
    final cached = _memberById(id);
    if (cached != null) return cached;
    await fetchMembers(refresh: members.isEmpty);
    return _memberById(id);
  }

  // ---------------------------------------------------------------------------
  // Group
  // ---------------------------------------------------------------------------

  String get groupName => (group?['name'] as String?) ?? 'PesaBox';
  String get groupType => (group?['type'] as String?) ?? 'Vikoba';
  String get groupLocation => (group?['location'] as String?) ?? '';

  double get groupSavings => _num(group, 'totalSavings');
  double get groupShares => _num(group, 'totalShares');
  double get groupSocialFund => _num(group, 'totalSocialFund');
  double get groupLoansOut => _num(group, 'totalLoans');
  double get groupFines => _num(group, 'totalFines');
  double get groupExpenses => _num(group, 'totalExpenses');
  int get memberCount =>
      (group?['memberCount'] as num?)?.toInt() ?? members.length;

  // Group financial rules (server/database.json "Groups") — the amounts and
  // limits configured for this group, used to prefill/validate the record
  // screens instead of hardcoding placeholder numbers.
  double get shareValue => _num(group, 'shareValue');
  int get minShares => (group?['minShares'] as num?)?.toInt() ?? 1;
  int get maxShares => (group?['maxShares'] as num?)?.toInt() ?? 5;
  double get socialFundContribution => _num(group, 'socialFundContribution');
  double get mandatorySavingsAmount => _num(group, 'mandatorySavingsAmount');
  double get loanInterestRate {
    final v = _num(group, 'loanInterestRate');
    return v > 0 ? v : 10;
  }

  int get maxLoanPeriodMonths {
    final v = (group?['maxLoanPeriodMonths'] as num?)?.toInt() ?? 0;
    return v > 0 ? v : 3;
  }

  static const _defaultFineReasons = [
    {'reason': 'Late Attendance', 'amount': 1000.0},
    {'reason': 'Absent', 'amount': 2000.0},
    {'reason': 'Missed Contribution', 'amount': 1000.0},
    {'reason': 'Late Loan Repayment', 'amount': 2000.0},
    {'reason': 'Other', 'amount': 0.0},
  ];

  /// The group's configured fine reasons ({reason, amount}), falling back to
  /// the platform defaults (mirrors server/main.go's defaultFineReasons) if
  /// the group hasn't configured its own yet.
  List<Map<String, dynamic>> get fineReasons {
    final raw = group?['fineReasons'];
    if (raw is List && raw.isNotEmpty) {
      final parsed = raw
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .where((r) => (r['reason'] as String?)?.isNotEmpty == true)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return _defaultFineReasons;
  }

  Future<Map<String, dynamic>?> fetchGroup({bool refresh = false}) async {
    if (group != null && !refresh) return group;
    try {
      group = await api.get('/group');
    } catch (_) {
      // keep existing cache
    }
    return group;
  }

  // ---------------------------------------------------------------------------
  // Lists
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchMembers(
      {bool refresh = false}) async {
    if (members.isNotEmpty && !refresh) return members;
    final groupId = group?['id'] as String?;
    if (groupId == null) return members;
    try {
      final data = await gql.query(
        r'''
          query($where: WhereMemberInput){
            members(where: $where) {
              id firstName lastName phone gender memberNumber status
              joinedAt groupId
            }
          }
        ''',
        {
          'where': {
            'groupId': {'equalTo': groupId},
          },
        },
      );
      final list = (data['members'] as List?) ?? const [];
      members = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    } catch (_) {
      // keep whatever was cached
    }
    return members;
  }

  /// Texts an OTP to [phone] to verify it before it can become a member
  /// (see [verifyMemberOtp] / [createMember]). SMTZ (the SMS provider) has
  /// no OTP concept of its own — it's just a bulk-SMS sender — so the
  /// backend generates and checks the code itself; while no SMTZ API key is
  /// configured server-side it always sends the same dev code, mirroring
  /// the login OTP flow.
  Future<void> requestMemberOtp(String phone) =>
      _restPost('/api/members/request-otp', {'phone': phone});

  /// Confirms [code] for [phone]. Must succeed before [createMember] will
  /// accept that phone — the backend rejects member creation for an
  /// unverified phone.
  Future<void> verifyMemberOtp(String phone, String code) =>
      _restPost('/api/members/verify-otp', {'phone': phone, 'code': code});

  /// Adds a new member to the current group. The phone must already have
  /// been verified via [requestMemberOtp] + [verifyMemberOtp] — the backend
  /// rejects this otherwise.
  Future<void> createMember({
    required String firstName,
    required String lastName,
    required String phone,
    required String gender,
    String? memberNumber,
  }) async {
    final groupId = group?['id'] as String?;
    if (groupId == null) {
      throw GraphQLException(tr('No group to add a member to'));
    }
    final created = await _restPost('/api/members', {
      'groupId': groupId,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'gender': gender,
      if (memberNumber != null && memberNumber.isNotEmpty)
        'memberNumber': memberNumber,
    });
    members = [...members, created];
  }

  /// POSTs JSON to a REST endpoint (not GraphQL) with the session's Bearer
  /// token, for the handful of routes — member OTP request/verify/create —
  /// that need real server-side validation a GraphQL auto-mutation can't
  /// express (see server/main.go's comment on why createMember isn't used).
  ///
  /// The backend's access tokens expire after just 15 minutes; a 401 here
  /// triggers one silent refresh-and-retry via [refreshSession] before
  /// giving up, so a mid-session expiry doesn't surface as a dead-end
  /// "Token expired" error during something like Add Member.
  Future<Map<String, dynamic>> _restPost(
    String path,
    Map<String, dynamic> body, {
    bool retrying = false,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final res = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}$path'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401 && !retrying && await refreshSession()) {
      return _restPost(path, body, retrying: true);
    }

    final decoded = jsonDecode(res.body);
    final data =
        decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
    if (res.statusCode >= 400) {
      throw GraphQLException(
        (data['error'] as String?) ??
            tr('Request failed ({0})', [res.statusCode]),
      );
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> fetchMeetings(
      {bool refresh = false}) async {
    if (meetings.isNotEmpty && !refresh) return meetings;
    try {
      meetings = await _list('/meetings');
    } catch (_) {}
    return meetings;
  }

  Map<String, dynamic>? _meetingById(String? id) {
    if (id == null) return null;
    for (final m in meetings) {
      if (m['id'] == id) return m;
    }
    return null;
  }

  /// Looks up a meeting by id, refreshing the meetings list once if it
  /// isn't cached yet.
  Future<Map<String, dynamic>?> meetingById(String? id) async {
    final cached = _meetingById(id);
    if (cached != null) return cached;
    await fetchMeetings(refresh: meetings.isEmpty);
    return _meetingById(id);
  }

  /// Marks [meetingId] as in progress — the Start Meeting screen's action.
  Future<void> startMeeting(String meetingId) async {
    await _restPost('/api/main/meetings/$meetingId/start', {});
    final i = meetings.indexWhere((m) => m['id'] == meetingId);
    if (i != -1) meetings[i] = {...meetings[i], 'status': 'in_progress'};
  }

  /// Creates a new meeting for the current group — the Create Meeting
  /// screen's action. `title` is required by the backend; the meeting
  /// number itself is assigned server-side (count of existing meetings + 1).
  Future<Map<String, dynamic>> createMeeting({
    required String title,
    String? date,
    String? time,
    String? location,
  }) async {
    final created = await _restPost('/api/main/meetings', {
      'title': title,
      if (date != null && date.isNotEmpty) 'date': date,
      if (time != null && time.isNotEmpty) 'time': time,
      if (location != null && location.isNotEmpty) 'location': location,
    });
    meetings = [created, ...meetings];
    return created;
  }

  /// Attendance rows already recorded for [meetingId] — each has
  /// `memberId`, `status`, and a `fullName` the backend joins in.
  Future<List<Map<String, dynamic>>> fetchMeetingAttendance(
          String meetingId) =>
      _list('/meetings/$meetingId/attendance');

  /// Records/updates attendance for [meetingId] — the Attendance screen's
  /// "Continue to activities" action. [statusByMemberId] maps memberId to
  /// one of present/late/absent/excused.
  Future<void> submitAttendance(
    String meetingId,
    Map<String, String> statusByMemberId,
  ) =>
      _restPost('/api/main/meetings/$meetingId/attendance', {
        'members': statusByMemberId.entries
            .map((e) => {'memberId': e.key, 'status': e.value})
            .toList(),
      });

  /// Closes [meetingId] (marks it completed) — the Review & Close screen's
  /// final action. Meeting has no dedicated REST route for this, so it goes
  /// through the framework's auto-generated GraphQL update mutation instead.
  Future<void> closeMeeting(String meetingId) async {
    // The auto-generated MeetingInput enforces the schema's `required: true`
    // flags even on update, so groupId (Meeting's only required field) has
    // to be resent alongside the actual change or the mutation 400s.
    final groupId = group?['id'];
    await gql.query(
      r'''
        mutation($input: MeetingInput!, $where: WhereMeetingInput){
          updateMeeting(input: $input, where: $where) { success message }
        }
      ''',
      {
        'input': {'groupId': groupId, 'status': 'completed'},
        'where': {
          'id': {'equalTo': meetingId},
        },
      },
    );
    final i = meetings.indexWhere((m) => m['id'] == meetingId);
    if (i != -1) meetings[i] = {...meetings[i], 'status': 'completed'};
  }

  Future<List<Map<String, dynamic>>> fetchTransactions(
      {bool refresh = false}) async {
    if (transactions.isNotEmpty && !refresh) return transactions;
    try {
      transactions = await _list('/transactions');
    } catch (_) {}
    return transactions;
  }

  /// Records a member-scoped transaction (contribution / share /
  /// social_fund) — the shared submit path for the meeting activity record
  /// screens. For a share purchase, pass [shareCount] instead of [amount]
  /// and the backend derives amount = shareCount * the group's shareValue.
  Future<Map<String, dynamic>> recordTransaction({
    required String type,
    required String memberId,
    String? meetingId,
    double? amount,
    int? shareCount,
    String method = 'Cash',
  }) async {
    final created = await _restPost('/api/main/transactions', {
      'type': type,
      'memberId': memberId,
      if (meetingId != null && meetingId.isNotEmpty) 'meetingId': meetingId,
      if (amount != null) 'amount': amount,
      if (shareCount != null) 'shareCount': shareCount,
      'method': method,
    });
    transactions = [created, ...transactions];
    return created;
  }

  /// Records a group expense (money out, not tied to a member) — the Group
  /// Expense screen's action.
  Future<Map<String, dynamic>> recordExpense({
    required double amount,
    required String description,
    String method = 'Cash',
    String? meetingId,
  }) async {
    final created = await _restPost('/api/main/expenses', {
      'amount': amount,
      'description': description,
      'method': method,
      if (meetingId != null && meetingId.isNotEmpty) 'meetingId': meetingId,
    });
    transactions = [created, ...transactions];
    return created;
  }

  /// Each member's live financial position (savings, shares, social fund,
  /// outstanding loans, fines) computed server-side from the group's actual
  /// Transactions/Loans/Fines — see GET /api/main/members/balances.
  List<Map<String, dynamic>> memberBalances = [];

  Future<List<Map<String, dynamic>>> fetchMemberBalances(
      {bool refresh = false}) async {
    if (memberBalances.isNotEmpty && !refresh) return memberBalances;
    try {
      memberBalances = await _list('/members/balances');
    } catch (_) {}
    return memberBalances;
  }

  Map<String, dynamic>? balanceFor(String? memberId) {
    if (memberId == null) return null;
    for (final b in memberBalances) {
      if (b['id'] == memberId) return b;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchLoans({bool refresh = false}) async {
    if (loans.isNotEmpty && !refresh) return loans;
    try {
      loans = await _list('/loans');
    } catch (_) {}
    return loans;
  }

  Map<String, dynamic>? _loanById(String? id) {
    if (id == null) return null;
    for (final l in loans) {
      if (l['id'] == id) return l;
    }
    return null;
  }

  /// Looks up a loan by id, refreshing the loans list once if it isn't
  /// cached yet.
  Future<Map<String, dynamic>?> loanById(String? id) async {
    final cached = _loanById(id);
    if (cached != null) return cached;
    await fetchLoans(refresh: loans.isEmpty);
    return _loanById(id);
  }

  /// Disburses a new loan — the Record Loan screen's action. Interest rate
  /// and repayment period come from the group's configured rules
  /// server-side; there's no per-loan override in this UI.
  Future<Map<String, dynamic>> createLoan({
    required String memberId,
    required double amount,
    String? meetingId,
    String method = 'Cash',
  }) async {
    final created = await _restPost('/api/main/loans', {
      'memberId': memberId,
      'amount': amount,
      if (meetingId != null && meetingId.isNotEmpty) 'meetingId': meetingId,
      'method': method,
    });
    loans = [created, ...loans];
    return created;
  }

  /// Records a repayment against [loanId] — the Record Repayment screen's
  /// action.
  Future<void> repayLoan(
    String loanId, {
    required double amount,
    String? meetingId,
    String method = 'Cash',
  }) async {
    await _restPost('/api/main/loans/$loanId/repayment', {
      'amount': amount,
      if (meetingId != null && meetingId.isNotEmpty) 'meetingId': meetingId,
      'method': method,
    });
    final i = loans.indexWhere((l) => l['id'] == loanId);
    if (i != -1) {
      final repaid = _num(loans[i], 'amountRepaid') + amount;
      final total = _num(loans[i], 'amount');
      loans[i] = {
        ...loans[i],
        'amountRepaid': repaid,
        'status': repaid >= total ? 'repaid' : 'active',
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchFines({bool refresh = false}) async {
    if (fines.isNotEmpty && !refresh) return fines;
    try {
      fines = await _list('/fines');
    } catch (_) {}
    return fines;
  }

  /// Issues a fine — the Record Fine screen's action. [amount] should be
  /// the configured amount for [reason] (see [fineReasons]) unless the admin
  /// typed an override (always required for the 'Other' reason).
  Future<Map<String, dynamic>> createFine({
    required String memberId,
    required String reason,
    required double amount,
    String? meetingId,
  }) async {
    final created = await _restPost('/api/main/fines', {
      'memberId': memberId,
      'reason': reason,
      'amount': amount,
      if (meetingId != null && meetingId.isNotEmpty) 'meetingId': meetingId,
    });
    fines = [created, ...fines];
    return created;
  }

  /// Records a payment against a fine — the Fines list's "mark paid" action.
  Future<void> payFine(
    String fineId, {
    required double amount,
    String method = 'Cash',
    String? meetingId,
  }) async {
    await _restPost('/api/main/fines/$fineId/pay', {
      'amount': amount,
      'method': method,
      if (meetingId != null && meetingId.isNotEmpty) 'meetingId': meetingId,
    });
    final i = fines.indexWhere((f) => f['id'] == fineId);
    if (i != -1) {
      final paid = _num(fines[i], 'amountPaid') + amount;
      final total = _num(fines[i], 'amount');
      fines[i] = {
        ...fines[i],
        'amountPaid': paid,
        'status': paid >= total ? 'paid' : 'pending',
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncements(
      {bool refresh = false}) async {
    if (announcements.isNotEmpty && !refresh) return announcements;
    try {
      announcements = await _list('/announcements');
    } catch (_) {}
    return announcements;
  }

  Future<List<Map<String, dynamic>>> fetchSmsActivity(
      {bool refresh = false}) async {
    if (smsActivity.isNotEmpty && !refresh) return smsActivity;
    try {
      smsActivity = await _list('/sms/activity');
    } catch (_) {}
    return smsActivity;
  }

  /// GETs a REST endpoint (not GraphQL) with the session's Bearer token —
  /// the read counterpart to [_restPost]. These `/api/main/*` routes (see
  /// server/main.go) require an authenticated group admin, which the old
  /// unauthenticated [api] client (pointed at a nonexistent `/api/v1` host)
  /// could never satisfy, so every list below silently returned empty.
  Future<dynamic> _restGet(String path, {bool retrying = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final res = await http
        .get(Uri.parse('${resolveApiBaseUrl()}$path'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401 && !retrying && await refreshSession()) {
      return _restGet(path, retrying: true);
    }

    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      final message = (decoded is Map ? decoded['error'] as String? : null) ??
          tr('Request failed ({0})', [res.statusCode]);
      throw GraphQLException(message);
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> _list(String path) async {
    final raw = await _restGet('/api/main$path');
    final list = raw is List ? raw : const [];
    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Derived helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? get nextMeeting {
    for (final m in meetings) {
      if (m['status'] == 'upcoming') return m;
    }
    return meetings.isEmpty ? null : meetings.first;
  }

  int get meetingsHeld =>
      meetings.where((m) => m['status'] == 'completed').length;

  static const List<String> _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Renders an ISO date (`2026-09-15`) as `15 Sep 2026`.
  String shortDate(Object? value) {
    final s = value?.toString() ?? '';
    final parts = s.split('-');
    if (parts.length != 3) return s;
    final month = int.tryParse(parts[1]) ?? 0;
    final monthName =
        (month >= 1 && month <= 12) ? _months[month] : parts[1];
    return '${parts[2]} $monthName ${parts[0]}';
  }

  String meetingSubtitle(Map<String, dynamic> meeting) {
    final time = meeting['time'] as String? ?? '';
    final date = shortDate(meeting['date']);
    return [date, time].where((s) => s.isNotEmpty).join(' · ');
  }

  /// Converts `21 Sep 2026 · 10:24 AM` to a short label like `21 Sep 2026`.
  String txnDateLabel(Object? value) {
    final s = value?.toString() ?? '';
    final sep = s.indexOf('·');
    return (sep >= 0 ? s.substring(0, sep) : s).trim();
  }

  /// `TZS 1,300,000`.
  String money(num? value) {
    final v = (value ?? 0).round();
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TZS $buf';
  }

  String amountLabel(Map<String, dynamic> txn) {
    final amount = (_num(txn, 'amount')).round();
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    final sign = (txn['direction'] as String?) == 'out' ? '-' : '+';
    return '$sign$buf';
  }

  String initials(String name) {
    final parts = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return ('$first$last').toUpperCase();
  }

  bool isCredit(Map<String, dynamic> txn) =>
      (txn['direction'] as String?) == 'in';

  /// Human-ish label for a transaction type.
  String txnTypeLabel(String type) {
    switch (type) {
      case 'contribution':
        return tr('Contribution');
      case 'share':
        return tr('Share purchase');
      case 'loan_disbursement':
        return tr('Loan disbursement');
      case 'loan_repayment':
        return tr('Loan repayment');
      case 'fine':
        return tr('Fine payment');
      case 'social_fund':
        return tr('Social fund');
      case 'expense':
        return tr('Group expense');
      case 'withdrawal':
        return tr('Withdrawal');
      default:
        return type.isEmpty ? tr('Transaction') : type;
    }
  }

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  static double _num(Map<String, dynamic>? m, String key) {
    final v = m?[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}