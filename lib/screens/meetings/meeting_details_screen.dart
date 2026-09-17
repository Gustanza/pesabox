import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class MeetingDetailsScreen extends StatefulWidget {
  const MeetingDetailsScreen({super.key, this.meetingId = '12'});

  final String meetingId;

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen> {
  Map<String, dynamic>? _meeting;
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _txns = [];
  int _memberCount = 0;
  bool _loading = true;

  static const List<Map<String, String>> _activities = [
    {'label': 'Contributions', 'type': 'contribution'},
    {'label': 'Shares', 'type': 'share'},
    {'label': 'Social Fund', 'type': 'social_fund'},
    {'label': 'Loan repayments', 'type': 'loan_repayment'},
    {'label': 'Fines', 'type': 'fine'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = AppState.I;
    final results = await Future.wait([
      state.meetingById(widget.meetingId),
      state.fetchMeetingAttendance(widget.meetingId),
      state.fetchTransactions(refresh: true),
      state.fetchMembers(),
    ]);
    if (!mounted) return;
    setState(() {
      _meeting = results[0] as Map<String, dynamic>?;
      _attendance = results[1] as List<Map<String, dynamic>>;
      _txns = (results[2] as List<Map<String, dynamic>>)
          .where((t) => t['meetingId'] == widget.meetingId)
          .toList();
      _memberCount = (results[3] as List<Map<String, dynamic>>).length;
      _loading = false;
    });
  }

  String get _title {
    final m = _meeting;
    if (m?['title']?.toString().isNotEmpty == true) return m!['title'].toString();
    return 'Meeting #${m?['meetingNumber'] ?? widget.meetingId}';
  }

  double _sumType(String type) => _txns
      .where((t) => t['type'] == type)
      .fold<double>(0, (sum, t) => sum + (t['amount'] as num? ?? 0));

  int _countType(String type) => _txns.where((t) => t['type'] == type).length;

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final meeting = _meeting;
    final attended = _attendance.where((a) => a['status'] == 'present' || a['status'] == 'late').length;
    final status = meeting?['status']?.toString() ?? 'upcoming';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  const ScreenBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink900),
                        ),
                        Text(
                          meeting == null ? '' : state.meetingSubtitle(meeting),
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (meeting == null)
                Text('Meeting not found.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600))
              else ...[
                Row(
                  children: [
                    Expanded(child: _StatBox(label: 'Attendance', value: '$attended/$_memberCount', color: AppColors.teal800)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBox(label: 'Savings', value: state.money(_sumType('contribution')), color: AppColors.green600)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _StatBox(label: 'Shares', value: state.money(_sumType('share')), color: AppColors.blue)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBox(label: 'Social Fund', value: state.money(_sumType('social_fund')), color: AppColors.gold500)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Meeting activity', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.md, border: Border.all(color: AppColors.line)),
                  child: Column(
                    children: [
                      for (var i = 0; i < _activities.length; i++) ...[
                        _ActivityRow(
                          label: _activities[i]['label']!,
                          count: _countType(_activities[i]['type']!),
                        ),
                        if (i < _activities.length - 1) const Divider(height: 1, indent: 48),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: status == 'completed'
                        ? null
                        : () {
                            final path = status == 'upcoming'
                                ? AppRouter.startMeetingPath(widget.meetingId)
                                : AppRouter.attendancePath(widget.meetingId);
                            Navigator.of(context).pushNamed(path);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green600,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                    ),
                    child: Text(
                      status == 'completed'
                          ? 'Meeting completed'
                          : (status == 'upcoming' ? 'Start meeting' : 'Continue meeting'),
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.ink400)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String label;
  final int count;

  const _ActivityRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final recorded = count > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: recorded ? AppColors.green100 : AppColors.line,
            ),
            child: Icon(
              recorded ? Icons.check_rounded : Icons.remove_rounded,
              size: 14,
              color: recorded ? AppColors.green600 : AppColors.ink400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink900)),
          ),
          Text(
            recorded ? '$count recorded' : 'None yet',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400),
          ),
        ],
      ),
    );
  }
}
