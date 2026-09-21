import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import 'dashboard_nav_bar.dart';

import '../../i18n/i18n.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasGroup = await AppState.I.checkGroupAssignment();
    if (!mounted) return;
    if (!hasGroup) {
      // Reachable via the bottom nav's Home tab even without a group (e.g.
      // tapped from the awaiting-assignment screen) — bounce back rather
      // than silently rendering a fake all-zero group.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.awaitingAssignment,
        (r) => false,
      );
      return;
    }
    await Future.wait([
      AppState.I.fetchTransactions(),
      AppState.I.fetchMeetings(),
    ]);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final upcoming = state.nextMeeting;
    final txns = state.transactions.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Hello, {0}', [AppState.I.userName.split(' ').first]),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(state.groupName),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.ink400,
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          size: 24,
                          color: AppColors.ink900,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.teal900, AppColors.teal800],
                    ),
                    borderRadius: AppRadius.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Group balance'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr(state.money(state.groupSavings +
                            state.groupShares +
                            state.groupSocialFund)),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _SubCard(
                        label: tr('Savings'),
                        amount: state.money(state.groupSavings),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SubCard(
                        label: tr('Shares'),
                        amount: state.money(state.groupShares),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _SubCard(
                        label: tr('Social Fund'),
                        amount: state.money(state.groupSocialFund),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SubCard(
                        label: tr('Loan fund out'),
                        amount: state.money(state.groupLoansOut),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  tr('Next meeting'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: upcoming == null
                      ? null
                      : () {
                          Navigator.of(context)
                              .pushNamed(AppRouter.meetingDetailsPath(
                            upcoming['id']?.toString() ?? '',
                          ));
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.md,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.green100,
                          ),
                          child: const Icon(
                            Icons.event_rounded,
                            size: 20,
                            color: AppColors.green600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                upcoming == null
                                    ? tr('No upcoming meeting')
                                    : (upcoming['title']?.toString() ??
                                        'Meeting #${upcoming['meetingNumber']}'),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                upcoming == null
                                    ? tr('Schedule one to get started')
                                    : state.meetingSubtitle(upcoming),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.ink400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold100,
                            borderRadius: AppRadius.sm,
                          ),
                          child: Text(
                            upcoming == null ? '' : tr('Upcoming'),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  tr('Quick actions'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.play_arrow_rounded,
                        label: tr('Start meeting'),
                        onTap: () {
                          final id = upcoming?['id']?.toString();
                          if (id == null || id.isEmpty) {
                            Navigator.of(context)
                                .pushNamed(AppRouter.createMeeting);
                            return;
                          }
                          Navigator.of(context)
                              .pushNamed(AppRouter.startMeetingPath(id));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.person_add_rounded,
                        label: tr('Add member'),
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRouter.addMember);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.request_quote_rounded,
                        label: tr('Record loan'),
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRouter.recordLoan);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.bar_chart_rounded,
                        label: tr('View reports'),
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRouter.reports);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('Recent activity'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(AppRouter.transactionsList);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        tr('See all →'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      if (txns.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            tr('No activity yet.'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.ink400,
                            ),
                          ),
                        )
                      else
                        for (var i = 0; i < txns.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 60),
                          _ActivityRow(
                            name: txns[i]['member']?.toString() ?? '',
                            initials: state.initials(
                                txns[i]['member']?.toString() ?? ''),
                            detail: state.txnTypeLabel(
                                txns[i]['type']?.toString() ?? ''),
                            amount: state.amountLabel(txns[i]),
                            isPositive: state.isCredit(txns[i]),
                            isFirst: i == 0,
                            isLast: i == txns.length - 1,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.transactionDetailsPath(
                                  txns[i]['id']?.toString() ?? '',
                                ),
                              );
                            },
                          ),
                        ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const DashboardNavBar(currentIndex: 0),
    );
  }
}

class _SubCard extends StatelessWidget {
  final String label;
  final String amount;

  const _SubCard({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(label),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.ink400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(amount),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green100,
              ),
              child: Icon(icon, size: 20, color: AppColors.green600),
            ),
            const SizedBox(height: 8),
            Text(
              tr(label),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.ink900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String name;
  final String initials;
  final String detail;
  final String amount;
  final bool isPositive;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const _ActivityRow({
    required this.name,
    required this.initials,
    required this.detail,
    required this.amount,
    required this.isPositive,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green100,
            ),
            child: Center(
              child: Text(
                tr(initials),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teal900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(name),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  tr(detail),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.ink400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            tr(amount),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPositive ? AppColors.green600 : AppColors.ink900,
            ),
          ),
        ],
      ),
      ),
    );
  }
}