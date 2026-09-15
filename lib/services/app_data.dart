import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart' hide resolveApiBaseUrl;
import 'graphql_client.dart';

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

  double get groupSavings => _num(group, 'savings');
  double get groupShares => _num(group, 'shares');
  double get groupSocialFund => _num(group, 'social');
  double get groupLoansOut => _num(group, 'loans');
  int get memberCount => int.tryParse(_str(group, 'members')) ?? 0;

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
      throw const GraphQLException('No group to add a member to');
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
        (data['error'] as String?) ?? 'Request failed (${res.statusCode})',
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

  Future<List<Map<String, dynamic>>> fetchTransactions(
      {bool refresh = false}) async {
    if (transactions.isNotEmpty && !refresh) return transactions;
    try {
      transactions = await _list('/transactions');
    } catch (_) {}
    return transactions;
  }

  Future<List<Map<String, dynamic>>> fetchLoans({bool refresh = false}) async {
    if (loans.isNotEmpty && !refresh) return loans;
    try {
      loans = await _list('/loans');
    } catch (_) {}
    return loans;
  }

  Future<List<Map<String, dynamic>>> fetchFines({bool refresh = false}) async {
    if (fines.isNotEmpty && !refresh) return fines;
    try {
      fines = await _list('/fines');
    } catch (_) {}
    return fines;
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

  Future<List<Map<String, dynamic>>> _list(String path) async {
    final raw = await api.getList(path);
    return raw
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
        return 'Contribution';
      case 'share':
        return 'Share purchase';
      case 'loan_disbursement':
        return 'Loan disbursement';
      case 'loan_repayment':
        return 'Loan repayment';
      case 'fine':
        return 'Fine payment';
      case 'social_fund':
        return 'Social fund';
      case 'expense':
        return 'Group expense';
      case 'withdrawal':
        return 'Withdrawal';
      default:
        return type.isEmpty ? 'Transaction' : type;
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

  static String _str(Map<String, dynamic>? m, String key) =>
      (m?[key] as String?) ?? '';
}