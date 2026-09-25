import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'graphql_client.dart';
import '../i18n/i18n.dart';
import '../brand.dart';

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

  /// True right after a first-time OTP login: the backend auto-creates the
  /// account with an empty firstName, which is the documented signal that
  /// the "complete your profile" screen (POST /api/me) needs to run before
  /// the app proceeds.
  bool get needsProfileCompletion =>
      ((user?['firstName'] as String?) ?? '').trim().isEmpty;
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
  /// [accessToken]/[refreshToken] come from the login response's
  /// `Set-Cookie` header (see [AuthService.verifyOtp]) — the JSON body never
  /// carries them.
  Future<void> setSession(
    Map<String, dynamic> loggedInUser,
    String accessToken,
    String? refreshTokenValue,
  ) async {
    token = accessToken;
    refreshToken = refreshTokenValue;
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

      // Like login, this may only set the new pair as Set-Cookie headers
      // rather than echoing them in the JSON body — check the cookie first
      // and fall back to the body for a server that does return it there.
      String? newAccess = extractCookie(res.headers, 'access_token');
      String? newRefresh = extractCookie(res.headers, 'refresh_token');
      if (newAccess == null) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) {
          newAccess = decoded['accessToken'] as String?;
          newRefresh ??= decoded['refreshToken'] as String?;
        }
      }
      if (newAccess == null || newAccess.isEmpty) return false;

      token = newAccess;
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
    // Best-effort: tell the server to drop the session too. Needs the
    // Accept header or /logout 307-redirects instead of returning JSON.
    try {
      final headers = {'Accept': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      await http
          .get(Uri.parse('${resolveApiBaseUrl()}/logout'), headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // clear the local session regardless
    }
    token = null;
    refreshToken = null;
    user = null;
    group = null;
    groupPosition = '';
    groupPermissions = {};
    await _persist();
  }

  /// POSTs the "complete your profile" form (step 3 of the OTP flow, shown
  /// when [needsProfileCompletion] is true). firstName is required by the
  /// backend (400 if blank); username/phone can't be changed here — that's
  /// the OTP login identifier. The backend responds `{"success": true}`
  /// rather than echoing the profile, so the cached user is updated locally.
  Future<void> completeProfile({
    required String firstName,
    String? lastName,
    String? email,
  }) async {
    await _restPost('/api/me', {
      'firstName': firstName,
      if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    user = {
      ...?user,
      'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
    };
    await _persist();
  }

  /// GET /me — always a fresh DB read (not decoded token claims), so it
  /// reflects a [completeProfile] update immediately. Safe to call on app
  /// resume / session checks; keeps the cached session on failure.
  Future<Map<String, dynamic>?> fetchMe() async {
    try {
      final data = await _restGet('/me');
      if (data is Map) {
        user = Map<String, dynamic>.from(data);
        await _persist();
      }
    } catch (_) {
      // keep whatever was cached
    }
    return user;
  }

  /// Whether this session has been assigned a group (i.e. a Super Admin has
  /// created a group and set this user as its admin). Populated by
  /// [checkGroupAssignment].
  bool get hasGroup => group != null;

  /// Looks up the group this user runs and their position in it, via
  /// `GET /api/main/group` (server/access_routes.go). The server decides:
  /// a mwenyekiti/katibu/mweka hazina/committee assignment, otherwise the
  /// group this user created or whose admin phone is theirs. Caches the group
  /// in [group] and the user's [groupPosition] / [groupPermissions].
  Future<bool> checkGroupAssignment(
      {bool refresh = false, bool throwOnError = false}) async {
    if (group != null && !refresh) return true;
    if (token == null) return false;
    try {
      final raw = await _restGet('/api/main/group');
      final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final g = data['group'];
      if (g is! Map) {
        group = null;
        return false;
      }
      group = Map<String, dynamic>.from(g);
      groupPosition = (data['position'] as String?) ?? '';
      groupPermissions = {
        for (final p in (data['permissions'] as List? ?? const [])) '$p',
      };
      return true;
    } on GraphQLException catch (e) {
      debugPrint('checkGroupAssignment: ${e.message}');
      // The session is dead (token expired and the one-time refresh token was
      // already used/revoked): forget it locally so the app asks for a new
      // login instead of wrongly saying "no group assigned".
      if (_isDeadSession(e.message)) {
        await _clearLocalSession();
        if (throwOnError) rethrow;
        return false;
      }
      // 403 "no group assigned to this account" — genuinely not assigned.
      if (e.message.contains('no group assigned')) {
        group = null;
        groupPosition = '';
        groupPermissions = {};
        return false;
      }
      if (throwOnError) rethrow;
      return group != null;
    } catch (e) {
      // Keep whatever was cached; don't flip an assigned group back to
      // "awaiting" just because a single request failed.
      debugPrint('checkGroupAssignment failed: $e');
      if (throwOnError) rethrow;
      return group != null;
    }
  }

  static bool _isDeadSession(String message) {
    final m = message.toLowerCase();
    return m.contains('token expired') ||
        m.contains('unauthorized') ||
        m.contains('revoked') ||
        m.contains('access token invalid') ||
        // a login issued by another server (e.g. live vs local)
        m.contains('domain mismatch');
  }

  /// Drops the stored session without calling the server (it already
  /// rejected it). [isSignedIn] is false afterwards.
  Future<void> _clearLocalSession() async {
    token = null;
    refreshToken = null;
    user = null;
    group = null;
    groupPosition = '';
    groupPermissions = {};
    await _persist();
  }

  bool get isSignedIn => token != null;

  /// This user's position in [group]: mwenyekiti (Group Admin), katibu,
  /// mweka_hazina or committee (Group Officers).
  String groupPosition = '';

  /// What this user may do in [group] (server/access.go permissions):
  /// group.settings, group.officers, group.operate, finance.write, ...
  Set<String> groupPermissions = {};

  /// Whether the server allows [permission] in this user's group. The server
  /// re-checks every request; this only decides what the app shows.
  bool can(String permission) => groupPermissions.contains(permission);

  /// The Mwenyekiti (Group Admin) — may change group settings and officers.
  bool get isGroupAdmin => can('group.settings');

  String get positionLabel {
    switch (groupPosition) {
      case 'mwenyekiti':
        return tr('Chairperson');
      case 'katibu':
        return tr('Secretary');
      case 'mweka_hazina':
        return tr('Treasurer');
      case 'committee':
        return tr('Committee member');
    }
    return isGroupAdmin ? tr('Group Admin') : tr('Group Officer');
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

  String get groupName => (group?['name'] as String?) ?? kBrandName;
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
  /// The group's flat loan interest (0 is a real rate: no interest).
  double get loanInterestRate =>
      group?['loanInterestRate'] == null ? 10 : _num(group, 'loanInterestRate');

  /// Max loan as a multiple of the member's savings + shares (0 = no limit).
  double get maxLoanMultiplier => _num(group, 'maxLoanMultiplier');

  /// The services the group has switched on (server/group_rules.go); a group
  /// that never set them uses the defaults.
  static const kDefaultServices = ['Shares', 'Mandatory Savings', 'Social Fund', 'Loans', 'Fines'];
  List<String> get enabledServices {
    final raw = group?['enabledServices'];
    if (raw is! List) return kDefaultServices;
    return [for (final s in raw) '$s'];
  }

  bool serviceEnabled(String service) => enabledServices.contains(service);
  bool get savingsEnabled =>
      serviceEnabled('Mandatory Savings') || serviceEnabled('Voluntary Savings');

  /// What a new loan of [amount] will cost under the current rules: flat
  /// interest (principal × rate / 100), charged once at issue.
  ({double interest, double totalDue}) loanPreview(double amount) {
    final interest = (amount * loanInterestRate / 100 * 100).round() / 100;
    return (interest: interest, totalDue: amount + interest);
  }

  /// The group's rules as the server normalises them:
  /// `{rules, canEdit, services, note}`.
  Future<Map<String, dynamic>> fetchGroupRules() async {
    final raw = await _restGet('/api/main/group/rules');
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  /// Saves rule changes (the server validates; its message is thrown), then
  /// reloads the group so every screen uses the new values.
  Future<Map<String, dynamic>> saveGroupRules(Map<String, dynamic> rules) async {
    final saved = await _restPost('/api/main/group/rules', rules);
    await checkGroupAssignment(refresh: true);
    return saved;
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

  /// Just delegates to [checkGroupAssignment] — the real, working source of
  /// group data (`/graphql`). Kept as a separate name because several
  /// screens already call it; there is no working `/api/v1/group` endpoint
  /// on the live backend for the old [api] client this used to call.
  Future<Map<String, dynamic>?> fetchGroup(
      {bool refresh = false, bool throwOnError = false}) async {
    await checkGroupAssignment(refresh: refresh, throwOnError: throwOnError);
    return group;
  }

  // ---------------------------------------------------------------------------
  // Lists
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchMembers(
      {bool refresh = false, bool throwOnError = false}) async {
    if (members.isNotEmpty && !refresh) return members;
    final groupId = group?['id'] as String?;
    if (groupId == null) {
      if (throwOnError) throw GraphQLException(tr('No group assigned yet'));
      return members;
    }
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
      // keep whatever was cached (reports ask for the error instead)
      if (throwOnError) rethrow;
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

  /// Edits an existing member's own fields (not username/phone-as-login —
  /// Members don't log in themselves, see CLAUDE.md) via `POST
  /// /api/main/members/:id` — server/main.go's comment says this route was
  /// built specifically for this screen. Only the fields passed are sent;
  /// the backend 400s if none are. Patches the local cache in place rather
  /// than refetching, since the backend only replies `{"success": true}`.
  Future<void> updateMember(
    String memberId, {
    String? firstName,
    String? lastName,
    String? phone,
    String? gender,
    String? memberNumber,
    String? status,
  }) async {
    final changes = {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (gender != null) 'gender': gender,
      if (memberNumber != null) 'memberNumber': memberNumber,
      if (status != null) 'status': status,
    };
    await _restPost('/api/main/members/$memberId', changes);
    final i = members.indexWhere((m) => m['id'] == memberId);
    if (i != -1) members[i] = {...members[i], ...changes};
    final bi = memberBalances.indexWhere((m) => m['id'] == memberId);
    if (bi != -1) memberBalances[bi] = {...memberBalances[bi], ...changes};
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
      {bool refresh = false, bool throwOnError = false}) async {
    if (meetings.isNotEmpty && !refresh) return meetings;
    try {
      meetings = await _list('/meetings');
    } catch (_) {
      // Callers that must not work from stale data (reports) get the error.
      if (throwOnError) rethrow;
    }
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
      {bool refresh = false, bool throwOnError = false}) async {
    if (transactions.isNotEmpty && !refresh) return transactions;
    try {
      transactions = await _list('/transactions');
    } catch (_) {
      // Callers that must not work from stale data (reports) get the error.
      if (throwOnError) rethrow;
    }
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
  Map<String, dynamic>? _transactionById(String? id) {
    if (id == null) return null;
    for (final t in transactions) {
      if (t['id'] == id) return t;
    }
    return null;
  }

  /// Looks up a transaction by id, refreshing the transactions list once if
  /// it isn't cached yet.
  Future<Map<String, dynamic>?> transactionById(String? id) async {
    final cached = _transactionById(id);
    if (cached != null) return cached;
    await fetchTransactions(refresh: transactions.isEmpty);
    return _transactionById(id);
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

  Future<List<Map<String, dynamic>>> fetchLoans({bool refresh = false, bool throwOnError = false}) async {
    if (loans.isNotEmpty && !refresh) return loans;
    try {
      loans = await _list('/loans');
    } catch (_) {
      // Callers that must not work from stale data (reports) get the error.
      if (throwOnError) rethrow;
    }
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

  Future<List<Map<String, dynamic>>> fetchFines({bool refresh = false, bool throwOnError = false}) async {
    if (fines.isNotEmpty && !refresh) return fines;
    try {
      fines = await _list('/fines');
    } catch (_) {
      // Callers that must not work from stale data (reports) get the error.
      if (throwOnError) rethrow;
    }
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

  /// Posts a new announcement — the Announcements screen's "New
  /// announcement" action. [priority] is `'normal'` or `'urgent'`.
  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    String? body,
    String priority = 'normal',
  }) async {
    final created = await _restPost('/api/main/announcements', {
      'title': title,
      if (body != null && body.isNotEmpty) 'body': body,
      'priority': priority,
    });
    announcements = [created, ...announcements];
    return created;
  }

  Future<List<Map<String, dynamic>>> fetchSmsActivity(
      {bool refresh = false, bool throwOnError = false}) async {
    if (smsActivity.isNotEmpty && !refresh) return smsActivity;
    try {
      smsActivity = await _list('/sms/activity');
    } catch (_) {
      // Callers that must not work from stale data (reports) get the error.
      if (throwOnError) rethrow;
    }
    return smsActivity;
  }

  /// GETs a REST endpoint (not GraphQL) with the session's Bearer token —
  /// the read counterpart to [_restPost]. These `/api/main/*` routes (see
  /// server/main.go) require an authenticated group admin.
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

  /// DELETEs a REST endpoint with the session's Bearer token.
  Future<void> _restDelete(String path, {bool retrying = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final res = await http
        .delete(Uri.parse('${resolveApiBaseUrl()}$path'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401 && !retrying && await refreshSession()) {
      return _restDelete(path, retrying: true);
    }
    if (res.statusCode >= 400) {
      final decoded = jsonDecode(res.body);
      throw GraphQLException(
        (decoded is Map ? decoded['error'] as String? : null) ??
            tr('Request failed ({0})', [res.statusCode]),
      );
    }
  }

  /// The Sender ID SMS go out as (set on the server: BEEM_SENDER_ID or the
  /// approved default), shown on the Settings screen.
  Future<String> fetchSmsSenderId() async {
    try {
      final raw = await _restGet('/api/admin/sms/settings');
      if (raw is Map && raw['senderId'] is String) return raw['senderId'] as String;
    } catch (_) {}
    return '—';
  }

  // ---------------------------------------------------------------------------
  // Group officers (Mwenyekiti manages Katibu / Mweka Hazina / committee)
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchOfficers() => _list('/officers');

  Future<void> addOfficer({
    required String phone,
    required String position,
    String firstName = '',
    String lastName = '',
  }) async {
    await _restPost('/api/main/officers', {
      'phone': phone,
      'position': position,
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  Future<void> removeOfficer(String assignmentId) =>
      _restDelete('/api/main/officers/$assignmentId');

  // ---------------------------------------------------------------------------
  // Government / outside loans to the group (TODO.md §7)
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> govLoans = [];

  Future<List<Map<String, dynamic>>> fetchGovLoans({bool refresh = false, bool throwOnError = false}) async {
    if (govLoans.isNotEmpty && !refresh) return govLoans;
    try {
      govLoans = await _list('/gov-loans');
    } catch (_) {
      // Callers that must not work from stale data (reports) get the error.
      if (throwOnError) rethrow;
    }
    return govLoans;
  }

  double get govLoansOutstanding =>
      govLoans.fold(0.0, (s, l) => s + ((l['outstanding'] as num?)?.toDouble() ?? 0));

  Future<void> recordGovLoan({
    required String lender,
    required double amount,
    String programme = '',
    String reference = '',
    double interestRate = 0,
    int termMonths = 0,
    String notes = '',
  }) async {
    await _restPost('/api/main/gov-loans', {
      'lender': lender,
      'amount': amount,
      'programme': programme,
      'reference': reference,
      'interestRate': interestRate,
      'termMonths': termMonths,
      'notes': notes,
    });
    await fetchGovLoans(refresh: true);
  }

  Future<void> repayGovLoan(String loanId, double amount,
      {String method = 'Cash', String reference = ''}) async {
    await _restPost('/api/main/gov-loans/$loanId/repayments', {
      'amount': amount,
      'method': method,
      'reference': reference,
    });
    await fetchGovLoans(refresh: true);
  }

  // ---------------------------------------------------------------------------
  // Corrections: financial records are never edited or deleted — a mistake
  // is undone by reversing the transaction (TODO.md D5 / N4).
  // ---------------------------------------------------------------------------

  Future<void> reverseTransaction(String transactionId, String reason) async {
    await _restPost('/api/main/transactions/$transactionId/reverse', {
      'reason': reason,
    });
    await Future.wait([
      fetchTransactions(refresh: true),
      checkGroupAssignment(refresh: true),
    ]);
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

  /// Formats a full ISO8601 timestamp (`createdAt`/`sentAt`/... straight off
  /// the backend, e.g. `2026-09-21T10:24:00Z`) as `21 Sep 2026` — unlike
  /// [shortDate], which expects a bare `YYYY-MM-DD` date and mangles
  /// anything with a time component.
  String isoDate(Object? value) {
    final dt = DateTime.tryParse(value?.toString() ?? '');
    if (dt == null) return value?.toString() ?? '';
    return '${dt.day} ${_months[dt.month]} ${dt.year}';
  }

  /// Same as [isoDate] but with a local time-of-day suffix:
  /// `21 Sep 2026 · 10:24 AM`.
  String isoDateTime(Object? value) {
    final dt = DateTime.tryParse(value?.toString() ?? '');
    if (dt == null) return value?.toString() ?? '';
    final local = dt.toLocal();
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 < 12 ? 'AM' : 'PM';
    return '${local.day} ${_months[local.month]} ${local.year} · '
        '$hour12:$minute $period';
  }

  String meetingSubtitle(Map<String, dynamic> meeting) {
    final time = meeting['time'] as String? ?? '';
    final date = shortDate(meeting['date']);
    return [date, time].where((s) => s.isNotEmpty).join(' · ');
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