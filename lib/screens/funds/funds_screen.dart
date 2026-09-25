import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _thisMonth = txns.where((t) {
        final dt = DateTime.tryParse(t['createdAt']?.toString() ?? '');
        return dt != null && dt.year == now.year && dt.month == now.month;
      }).toList();
      _loading = false;
    });
  }

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
                        label: 'Savings fund',
                        value: state.money(state.groupSavings),
                        valueColor: AppColors.teal800,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: 'Share fund',
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
                        label: 'Social Fund',
                        value: state.money(state.groupSocialFund),
                        valueColor: AppColors.gold500,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: 'Loan fund out',
                        value: state.money(state.groupLoansOut),
                        valueColor: AppColors.danger,
                      ),
                    ),
                  ],
                ),
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
                            '${state.money(_sum('contribution'))} in · ${state.money(_sum('withdrawal'))} out',
                        color: AppColors.teal800,
                      ),
                      const Divider(height: 1, indent: 56),
                      _FundRow(
                        icon: Icons.pie_chart_outline_rounded,
                        name: 'Shares',
                        detail: '${state.money(_sum('share'))} in · TZS 0 out',
                        color: AppColors.info,
                      ),
                      const Divider(height: 1, indent: 56),
                      _FundRow(
                        icon: Icons.favorite_outline_rounded,
                        name: 'Social Fund',
                        detail:
                            '${state.money(_sum('social_fund'))} in · TZS 0 out',
                        color: AppColors.gold500,
                      ),
                      const Divider(height: 1, indent: 56),
                      _FundRow(
                        icon: Icons.request_quote_outlined,
                        name: 'Loan fund',
                        detail:
                            '${state.money(_sum('loan_repayment'))} in · ${state.money(_sum('loan_disbursement'))} out',
                        color: AppColors.teal700,
                      ),
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