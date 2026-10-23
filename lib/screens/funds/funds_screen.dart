import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';

class FundsScreen extends StatefulWidget {
  const FundsScreen({super.key});

  @override
  State<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends State<FundsScreen> with AutoRefreshOnPop {
  List<Map<String, dynamic>> _thisMonth = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onReturnedToScreen() => _load();

  Future<void> _load() async {
    final state = AppState.I;
    await state.checkGroupAssignment(refresh: true);
    final txns = await state.fetchTransactions(refresh: true);
    await state.fetchLoans(refresh: true); // loans outstanding = the loans' balances
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _thisMonth = txns.where((t) {
        if (t['reversed'] == true) return false; // undone: not money moved
        final dt = DateTime.tryParse(t['createdAt']?.toString() ?? '');
        return dt != null && dt.year == now.year && dt.month == now.month;
      }).toList();
      _loading = false;
    });
  }

  String _inOut(double inAmount, double outAmount) => tr('{0} in · {1} out',
      [AppState.I.money(inAmount), AppState.I.money(outAmount)]);

  /// Sum of [field] over this month's share-out transactions: each payment
  /// splits into savingsReturned + sharesReturned + profit (server/payouts.go).
  double _shareOut(String field) => _thisMonth
      .where((t) => t['type'] == 'share_out')
      .fold<double>(0, (sum, t) => sum + ((t[field] as num?)?.toDouble() ?? 0));

  double _sum(String type) => _thisMonth
      .where((t) => t['type'] == type)
      .fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final totalIn = _thisMonth
        .where((t) => t['direction'] == 'in')
        .fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
    final totalOut = _thisMonth
        .where((t) => t['direction'] == 'out')
        .fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
    final net = totalIn - totalOut;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x16),
              HxHeader(title: tr('Funds')),
              const SizedBox(height: AppSpace.x20),
              if (_loading)
                const _LoadingSkeleton()
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: HxStat(
                        label: tr('Savings fund'),
                        value: state.money(state.groupSavings),
                        valueColor: AppColors.teal800,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: tr('Share fund'),
                        value: state.money(state.groupShares),
                        valueColor: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x12),
                Row(
                  children: [
                    Expanded(
                      child: HxStat(
                        label: tr('Social Fund'),
                        value: state.money(state.groupSocialFund),
                        valueColor: AppColors.gold500,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: tr('Loan fund out'),
                        value: state.money(state.groupLoansOut),
                        valueColor: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                if (state.can('finance.write')) ...[
                  const SizedBox(height: AppSpace.x16),
                  HxButton(
                    key: const ValueKey('social-fund-payout'),
                    text: tr('Social fund payout'),
                    variant: HxButtonVariant.secondary,
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppRouter.socialFundPayout),
                  ),
                ],
                const SizedBox(height: AppSpace.x24),
                const HxSectionTitle(title: 'Fund movement this month'),
                const SizedBox(height: AppSpace.x12),
                HxSurface(
                  child: Column(
                    children: [
                      _KVRow(
                        label: 'Total in',
                        value: HxMoney(text: state.money(totalIn)),
                      ),
                      const Divider(height: 24),
                      _KVRow(
                        label: 'Total out',
                        value: HxMoney(text: state.money(totalOut)),
                      ),
                      const Divider(height: 24),
                      _KVRow(
                        label: 'Net movement',
                        value: HxMoney.signed(
                          text:
                              '${net >= 0 ? '+' : '-'}${state.money(net.abs())}',
                          positive: net >= 0,
                          autoSign: false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x24),
                const HxSectionTitle(title: 'By fund this month'),
                const SizedBox(height: AppSpace.x12),
                HxSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _FundRow(
                        icon: Icons.savings_outlined,
                        name: 'Savings',
                        detail:
                            _inOut(_sum('contribution'),
                                _sum('withdrawal') + _shareOut('savingsReturned')),
                        color: AppColors.teal800,
                      ),
                      const Divider(height: 1, indent: 56),
                      _FundRow(
                        icon: Icons.pie_chart_outline_rounded,
                        name: 'Shares',
                        detail: _inOut(_sum('share'), _shareOut('sharesReturned')),
                        color: AppColors.info,
                      ),
                      const Divider(height: 1, indent: 56),
                      _FundRow(
                        icon: Icons.favorite_outline_rounded,
                        name: 'Social Fund',
                        detail: _inOut(
                            _sum('social_fund'), _sum('social_fund_payout')),
                        color: AppColors.gold500,
                      ),
                      const Divider(height: 1, indent: 56),
                      _FundRow(
                        icon: Icons.request_quote_outlined,
                        name: 'Loan fund',
                        detail:
                            _inOut(_sum('loan_repayment'), _sum('loan_disbursement')),
                        color: AppColors.teal700,
                      ),
                      if (_sum('share_out') > 0) ...[
                        const Divider(height: 1, indent: 56),
                        _FundRow(
                          key: const ValueKey('fund-share-out'),
                          icon: Icons.call_split_rounded,
                          name: 'Share-out',
                          detail: tr('{0} paid · {1} of it profit', [
                            state.money(_sum('share_out')),
                            state.money(_shareOut('profit')),
                          ]),
                          color: AppColors.info,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.x24),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HxSkeletonStats(),
        SizedBox(height: AppSpace.x12),
        HxSkeletonStats(),
        SizedBox(height: AppSpace.x20),
        HxSkeleton(width: 170, height: 14),
        SizedBox(height: AppSpace.x12),
        HxSkeleton(height: 120),
        SizedBox(height: AppSpace.x20),
        HxSkeleton(width: 140, height: 14),
        SizedBox(height: AppSpace.x12),
        HxSkeleton(height: 220),
      ],
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final Widget value;

  const _KVRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr(label),
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
        ),
        value,
      ],
    );
  }
}

class _FundRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String detail;
  final Color color;

  const _FundRow({
    super.key,
    required this.icon,
    required this.name,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16, vertical: AppSpace.x12),
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
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(name),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}