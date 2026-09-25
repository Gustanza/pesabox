import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';

class MeetingDetailsScreen extends StatefulWidget {
  const MeetingDetailsScreen({super.key, this.meetingId = '12'});

  final String meetingId;

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen>
    with AutoRefreshOnPop {
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

  @override
  void onReturnedToScreen() => _load();

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
    return tr('Meeting #{0}', [m?['meetingNumber'] ?? widget.meetingId]);
  }

  double _sumType(String type) => _txns
      .where((t) => t['type'] == type)
      .fold<double>(0, (sum, t) => sum + (t['amount'] as num? ?? 0));

  int _countType(String type) => _txns.where((t) => t['type'] == type).length;

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final meeting = _meeting;
    final attended = _attendance
        .where(
            (a) => a['status'] == 'present' || a['status'] == 'late')
        .length;
    final status = meeting?['status']?.toString() ?? 'upcoming';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x16),
              HxHeader(
                title: _loading ? 'Meeting' : tr(_title),
                subtitle: meeting == null
                    ? null
                    : tr(state.meetingSubtitle(meeting)),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: AppSpace.x20),
              if (_loading)
                const _LoadingSkeleton()
              else if (meeting == null)
                const HxEmpty(
                  icon: Icons.event_busy_rounded,
                  title: 'Meeting not found',
                  message: 'This meeting may have been deleted.',
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: HxStat(
                        label: tr('Attendance'),
                        value: '$attended/$_memberCount',
                        valueColor: AppColors.teal800,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: tr('Savings'),
                        value: state.money(_sumType('contribution')),
                        valueColor: AppColors.teal800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x12),
                Row(
                  children: [
                    Expanded(
                      child: HxStat(
                        label: tr('Shares'),
                        value: state.money(_sumType('share')),
                        valueColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: tr('Social Fund'),
                        value: state.money(_sumType('social_fund')),
                        valueColor: AppColors.gold500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x24),
                const HxSectionTitle(title: 'Meeting activity'),
                const SizedBox(height: AppSpace.x12),
                HxSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < _activities.length; i++) ...[
                        _ActivityRow(
                          label: _activities[i]['label']!,
                          count: _countType(_activities[i]['type']!),
                        ),
                        if (i < _activities.length - 1)
                          const Divider(height: 1, indent: 48),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x32),
                HxButton(
                  text: switch (status) {
                    'completed' => tr('Meeting completed'),
                    'upcoming' => tr('Start meeting'),
                    _ => tr('Continue meeting'),
                  },
                  onPressed: status == 'completed'
                      ? null
                      : () {
                          final path = status == 'upcoming'
                              ? AppRouter.startMeetingPath(widget.meetingId)
                              : AppRouter.attendancePath(widget.meetingId);
                          Navigator.of(context).pushNamed(path);
                        },
                ),
              ],
              const SizedBox(height: AppSpace.x32),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HxSkeletonStats(),
        const SizedBox(height: AppSpace.x12),
        const HxSkeletonStats(),
        const SizedBox(height: AppSpace.x20),
        const HxSkeleton(width: 140, height: 14),
        const SizedBox(height: AppSpace.x12),
        const HxSkeletonList(rows: 5),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
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
              color: recorded ? AppColors.teal800 : AppColors.ink400,
            ),
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Text(
              tr(label),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ink900,
              ),
            ),
          ),
          Text(
            recorded ? tr('{0} recorded', [count]) : tr('None yet'),
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400),
          ),
        ],
      ),
    );
  }
}