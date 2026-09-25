import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../dashboard/dashboard_nav_bar.dart';

import '../../i18n/i18n.dart';

class MeetingsListScreen extends StatefulWidget {
  const MeetingsListScreen({super.key});

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen>
    with AutoRefreshOnPop {
  List<Map<String, dynamic>> _meetings = [];
  bool _loading = true;
  int _view = 0; // 0 = Upcoming, 1 = History

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onReturnedToScreen() => _load();

  Future<void> _load() async {
    final list = await AppState.I.fetchMeetings(refresh: true);
    if (mounted) {
      setState(() {
        _meetings = list;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visible {
    if (_view == 0) {
      return _meetings.where((m) => m['status'] == 'upcoming').toList();
    }
    return _meetings.where((m) => m['status'] != 'upcoming').toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final visible = _visible;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.x20, AppSpace.x16, 20, 0),
              child: Row(
                children: [
                  const Expanded(child: HxPageTitle(title: 'Meetings')),
                  HxIconButton(
                    icon: Icons.add_rounded,
                    tooltip: tr('Create meeting'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.createMeeting);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CycleCard(
                      held: state.meetingsHeld,
                      cycleNumber: (state.group?['cycleCurrent'] as num?)
                              ?.toInt() ??
                          1,
                      total: (state.group?['cycleTotal'] as num?)?.toInt() ??
                          30,
                      startedLabel: state.group?['formationDate'] == null
                          ? ''
                          : tr('Since {0}', [
                              state.isoDate(state.group?['formationDate']),
                            ]),
                    ),
                    const SizedBox(height: AppSpace.x16),
                    HxSegment(
                      options: [tr('Upcoming'), tr('History')],
                      selected: _view,
                      onChanged: (i) => setState(() => _view = i),
                    ),
                    const SizedBox(height: AppSpace.x16),
                    _MeetingList(meetings: visible, loading: _loading),
                    const SizedBox(height: AppSpace.x24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DashboardNavBar(currentIndex: 2),
    );
  }
}

class _CycleCard extends StatelessWidget {
  final int held;
  final int cycleNumber;
  final int total;
  final String startedLabel;

  const _CycleCard({
    this.held = 0,
    this.cycleNumber = 1,
    this.total = 30,
    this.startedLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (held / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.x20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink900, AppColors.teal900],
        ),
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('CYCLE {0}', [cycleNumber]),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  if (startedLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      startedLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$held / $total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    tr('meetings held'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0x33FFFFFF),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.green500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                tr('{0} meetings remaining', [total - held]),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              // Closing the cycle is a core group decision — Mwenyekiti only.
              if (AppState.I.isGroupAdmin)
                Pressable(
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRouter.closeCycle);
                  },
                  child: Text(
                    tr('Close cycle →'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8FE3BE),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeetingList extends StatelessWidget {
  final List<Map<String, dynamic>> meetings;
  final bool loading;

  const _MeetingList({required this.meetings, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const HxSkeletonList(rows: 4);

    if (meetings.isEmpty) {
      return HxEmpty(
        icon: Icons.event_rounded,
        title: 'No meetings here',
        message: 'Schedule a new meeting to see it appear here.',
      );
    }

    final state = AppState.I;
    return HxSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < meetings.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64),
            HxRow(
              onTap: () {
                Navigator.of(context).pushNamed(
                  AppRouter.meetingDetailsPath(
                    meetings[i]['id']?.toString() ?? '',
                  ),
                );
              },
              leading: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green100,
                ),
                child: const Icon(
                  Icons.event_rounded,
                  size: 18,
                  color: AppColors.teal800,
                ),
              ),
              title:
                  meetings[i]['title']?.toString() ??
                  tr('Meeting #{0}', [meetings[i]['meetingNumber']]),
              subtitle: state.meetingSubtitle(meetings[i]),
              trailing: HxPill(
                text: meetings[i]['status'] == 'upcoming'
                    ? tr('Upcoming')
                    : tr('Closed'),
                tone: meetings[i]['status'] == 'upcoming'
                    ? HxPillTone.warning
                    : HxPillTone.neutral,
              ),
            ),
          ],
        ],
      ),
    );
  }
}