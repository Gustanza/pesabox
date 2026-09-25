import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
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
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.x20, AppSpace.x16, AppSpace.x20, 0),
              child: Row(
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
                    Row(
                      children: [
                        Expanded(
                          child: HxStat(
                            label: tr('Members'),
                            value: '$memberTotal',
                            valueColor: AppColors.teal800,
                          ),
                        ),
                        const SizedBox(width: AppSpace.x12),
                        Expanded(
                          child: HxStat(
                            label: tr('Meetings held'),
                            value: '${state.meetingsHeld}',
                            valueColor: AppColors.teal800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x24),
                    HxSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          HxMenuRow(
                            icon: Icons.group_outlined,
                            title: tr('Members'),
                            color: AppColors.teal800,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.membersList);
                            },
                          ),
                          HxMenuRow(
                            icon: Icons.event_rounded,
                            title: tr('Meetings'),
                            color: AppColors.info,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.meetingsList);
                            },
                          ),
                          HxMenuRow(
                            icon: Icons.account_balance_wallet_outlined,
                            title: tr('Funds'),
                            color: AppColors.gold500,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.funds);
                            },
                          ),
                          HxMenuRow(
                            icon: Icons.request_quote_outlined,
                            title: tr('Loans'),
                            color: AppColors.teal700,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.loansList);
                            },
                          ),
                          HxMenuRow(
                            icon: Icons.account_balance_outlined,
                            title: tr('Government loans'),
                            color: AppColors.teal800,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.govLoans);
                            },
                          ),
                          HxMenuRow(
                            icon: Icons.gavel_outlined,
                            title: tr('Fines'),
                            color: AppColors.danger,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.finesList);
                            },
                          ),
                          HxMenuRow(
                            icon: Icons.scale_outlined,
                            title: tr('Rules & constitution'),
                            color: AppColors.teal700,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.rulesConstitution);
                            },
                          ),
                          HxMenuRow(
                            icon: Icons.campaign_outlined,
                            title: tr('Announcements'),
                            color: AppColors.info,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.announcements);
                            },
                          ),
                          HxMenuRow(
                            icon: Icons.badge_outlined,
                            title: tr('Group officers'),
                            color: AppColors.gold500,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.officers);
                            },
                          ),
                          HxMenuRow(
                            icon: Icons.info_outline_rounded,
                            title: tr('Group information'),
                            color: AppColors.ink600,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.editGroup);
                            },
                            addDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.x24),
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