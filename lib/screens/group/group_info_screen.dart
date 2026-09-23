import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../dashboard/dashboard_nav_bar.dart';

import '../../i18n/i18n.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      AppState.I.fetchGroup(),
      AppState.I.fetchMembers(),
      AppState.I.fetchMeetings(),
    ]);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final memberTotal =
        state.members.isNotEmpty ? state.members.length : state.memberCount;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(state.groupName),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [state.positionLabel, state.groupType, state.groupLocation]
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.teal900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: tr('Members'),
                            value: '$memberTotal',
                            color: AppColors.teal800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBox(
                            label: tr('Meetings held'),
                            value: '${state.meetingsHeld}',
                            color: AppColors.green600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.md,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          _MenuRow(
                            icon: Icons.group_outlined,
                            title: tr('Members'),
                            color: AppColors.teal800,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.membersList);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuRow(
                            icon: Icons.event_rounded,
                            title: tr('Meetings'),
                            color: AppColors.blue,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.meetingsList);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuRow(
                            icon: Icons.account_balance_wallet_outlined,
                            title: tr('Funds'),
                            color: AppColors.gold500,
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRouter.funds);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuRow(
                            icon: Icons.request_quote_outlined,
                            title: tr('Loans'),
                            color: AppColors.green600,
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRouter.loansList);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuRow(
                            icon: Icons.account_balance_outlined,
                            title: tr('Government loans'),
                            color: AppColors.teal800,
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRouter.govLoans);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuRow(
                            icon: Icons.gavel_outlined,
                            title: tr('Fines'),
                            color: AppColors.danger,
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRouter.finesList);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuRow(
                            icon: Icons.scale_outlined,
                            title: tr('Rules & constitution'),
                            color: AppColors.teal700,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.rulesConstitution);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuRow(
                            icon: Icons.campaign_outlined,
                            title: tr('Announcements'),
                            color: AppColors.blue,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.announcements);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuRow(
                            icon: Icons.badge_outlined,
                            title: tr('Group officers'),
                            color: AppColors.gold500,
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRouter.officers);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuRow(
                            icon: Icons.info_outline_rounded,
                            title: tr('Group information'),
                            color: AppColors.ink600,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.editGroup);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DashboardNavBar(currentIndex: 1),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(label),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.ink400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr(value),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(title),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}