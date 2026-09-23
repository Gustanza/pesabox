import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
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

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AuthHeader(title: tr('Funds')),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Savings fund',
                        value: state.money(state.groupSavings),
                        color: AppColors.teal800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: 'Share fund',
                        value: state.money(state.groupShares),
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Social Fund',
                        value: state.money(state.groupSocialFund),
                        color: AppColors.gold500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: 'Loan fund out',
                        value: state.money(state.groupLoansOut),
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  tr('Fund movement this month'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      _KVRow(label: 'Total in', value: state.money(totalIn)),
                      const Divider(height: 24),
                      _KVRow(label: 'Total out', value: state.money(totalOut)),
                      const Divider(height: 24),
                      _KVRow(
                        label: 'Net movement',
                        value:
                            '${totalIn - totalOut >= 0 ? '+' : ''}${state.money(totalIn - totalOut)}',
                        positive: totalIn - totalOut >= 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  tr('By fund this month'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
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
                        color: AppColors.blue,
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
                        color: AppColors.green600,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
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
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final bool positive;

  const _KVRow({required this.label, required this.value, this.positive = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr(label),
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
        ),
        Text(
          tr(value),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: positive ? AppColors.green600 : AppColors.ink900,
          ),
        ),
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
