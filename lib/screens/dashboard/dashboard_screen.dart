import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import 'dashboard_nav_bar.dart';

import '../../i18n/i18n.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutoRefreshOnPop {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Refetches everything the dashboard shows — including the group's own
  // balance totals, which the backend computes server-side — whenever this
  // screen is first shown or becomes visible again after a deeper screen
  // (meeting activity, record loan, ...) pops back to it.
  @override
  void onReturnedToScreen() => _load(refresh: true);

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() => _loading = true);
    }
    final hasGroup = await AppState.I.checkGroupAssignment(refresh: refresh);
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
      AppState.I.fetchTransactions(refresh: refresh),
      AppState.I.fetchMeetings(refresh: refresh),
      AppState.I.fetchLoans(refresh: refresh), // loans outstanding card
    ]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final upcoming = state.nextMeeting;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _greeting(state),
              const SizedBox(height: AppSpace.x20),
              if (_loading)
                _loadingBlock()
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
                  child: _balanceHero(state),
                ),
                const SizedBox(height: AppSpace.x16),
                _balanceGrid(state),
                const SizedBox(height: AppSpace.x24),
                _nextMeeting(state, upcoming),
                const SizedBox(height: AppSpace.x24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
                  child: HxSectionTitle(title: 'Quick actions'),
                ),
                const SizedBox(height: AppSpace.x12),
                _quickActions(state, upcoming),
                const SizedBox(height: AppSpace.x24),
                _recentActivity(state),
                const SizedBox(height: AppSpace.x24),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const DashboardNavBar(currentIndex: 0),
    );
  }

  /// Header when data is still in flight.
  Widget _loadingBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: const HxSkeleton(height: 120, radius: AppRadius.lg),
        ),
        const SizedBox(height: AppSpace.x16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: HxSkeletonStats(),
        ),
        const SizedBox(height: AppSpace.x20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: HxSectionTitle(title: 'Quick actions'),
        ),
        const SizedBox(height: AppSpace.x12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Row(
            children: [
              Expanded(child: HxSkeleton(height: 76)),
              SizedBox(width: AppSpace.x12),
              Expanded(child: HxSkeleton(height: 76)),
              SizedBox(width: AppSpace.x12),
              Expanded(child: HxSkeleton(height: 76)),
              SizedBox(width: AppSpace.x12),
              Expanded(child: HxSkeleton(height: 76)),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: HxSectionTitle(title: 'Recent activity'),
        ),
        const SizedBox(height: AppSpace.x12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: HxSkeletonList(rows: 3),
        ),
      ],
    );
  }

  Widget _greeting(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Hello, {0}', [state.userName.split(' ').first]),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tr(state.groupName),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.ink400,
                  ),
                ),
              ],
            ),
          ),
          // Announcements: the one place a "something new happened" affordance
          // leads somewhere real — never ship a bell that does nothing.
          HxIconButton(
            icon: Icons.notifications_outlined,
            tooltip: tr('Announcements'),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.announcements),
          ),
        ],
      ),
    );
  }

  Widget _balanceHero(AppState state) {
    return HxHero(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr('Group balance'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
            const Icon(
              Icons.verified_rounded,
              size: 16,
              color: AppColors.teal100,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.x8),
        Text(
          tr(state.money(state.groupSavings +
              state.groupShares +
              state.groupSocialFund)),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _balanceGrid(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SubCard(
                  label: tr('Savings'),
                  amount: HxMoney(text: state.money(state.groupSavings), fontSize: 15),
                ),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: _SubCard(
                  label: tr('Shares'),
                  amount: HxMoney(text: state.money(state.groupShares), fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          Row(
            children: [
              Expanded(
                child: _SubCard(
                  label: tr('Social Fund'),
                  amount:
                      HxMoney(text: state.money(state.groupSocialFund), fontSize: 15),
                ),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: _SubCard(
                  label: tr('Loan fund out'),
                  amount: HxMoney(text: state.money(state.groupLoansOut), fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextMeeting(AppState state, Map<String, dynamic>? upcoming) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: HxSectionTitle(title: 'Next meeting'),
        ),
        const SizedBox(height: AppSpace.x12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: HxSurface(
            padding: const EdgeInsets.all(AppSpace.x16),
            onTap: upcoming == null
                ? null
                : () => Navigator.of(context).pushNamed(
                      AppRouter.meetingDetailsPath(
                        upcoming['id']?.toString() ?? '',
                      ),
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
                    color: AppColors.teal800,
                  ),
                ),
                const SizedBox(width: AppSpace.x12),
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
                      const SizedBox(height: 3),
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
                if (upcoming != null)
                  const Padding(
                    padding: EdgeInsets.only(left: AppSpace.x8),
                    child: HxPill(text: 'Upcoming', tone: HxPillTone.warning),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickActions(AppState state, Map<String, dynamic>? upcoming) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
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
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: _QuickAction(
              icon: Icons.person_add_rounded,
              label: tr('Add member'),
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.addMember);
              },
            ),
          ),
          const SizedBox(width: AppSpace.x12),
          if (AppState.I.serviceEnabled('Loans')) ...[
            Expanded(
              child: _QuickAction(
                icon: Icons.request_quote_rounded,
                label: tr('Record loan'),
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.recordLoan);
                },
              ),
            ),
            const SizedBox(width: AppSpace.x12),
          ],
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
    );
  }

  Widget _recentActivity(AppState state) {
    final txns = state.transactions.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HxSectionTitle(title: 'Recent activity'),
              HxLink(
                text: tr('See all'),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRouter.transactionsList),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: HxSurface(
            padding: EdgeInsets.zero,
            child: txns.isEmpty
                ? HxEmpty(
                    card: false,
                    icon: Icons.receipt_long_rounded,
                    title: 'No activity yet',
                    message: 'Record your first contribution to get started.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < txns.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 68),
                        _ActivityRow(
                          name: txns[i]['fullName']?.toString() ??
                              txns[i]['memberName']?.toString() ??
                              '',
                          initials: state.initials(
                            txns[i]['fullName']?.toString() ??
                                txns[i]['memberName']?.toString() ??
                                '',
                          ),
                          detail: state.txnTypeLabel(
                              txns[i]['type']?.toString() ?? ''),
                          amount: state.amountLabel(txns[i]),
                          isPositive: state.isCredit(txns[i]),
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
      ],
    );
  }
}

class _SubCard extends StatelessWidget {
  final String label;
  final Widget amount;

  const _SubCard({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return HxSurface(
      padding: const EdgeInsets.all(AppSpace.x16),
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
          const SizedBox(height: AppSpace.x8),
          amount,
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
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x16),
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
              child: Icon(icon, size: 20, color: AppColors.teal800),
            ),
            const SizedBox(height: AppSpace.x8),
            Text(
              label,
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
  final VoidCallback? onTap;

  const _ActivityRow({
    required this.name,
    required this.initials,
    required this.detail,
    required this.amount,
    required this.isPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HxRow(
      onTap: onTap,
      leading: HxAvatar(initials: tr(initials), size: 36),
      title: tr(name),
      subtitle: tr(detail),
      trailing: HxMoney.signed(
        text: amount,
        positive: isPositive,
        fontSize: 14,
      ),
    );
  }
}