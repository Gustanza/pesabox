import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../dashboard/dashboard_nav_bar.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  static const List<String> _chips = [
    'All',
    'Savings',
    'Shares',
    'Loans',
    'Fines',
    'Expenses',
  ];

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AppState.I.fetchTransactions();
    if (mounted) setState(() => _transactions = list);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final txns = _transactions;

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
                  Text(
                    'Activity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
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
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: TransactionsListScreen._chips.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return _Chip(
                            label: TransactionsListScreen._chips[index],
                            active: index == 0,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'More',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MoreItem(
                          icon: Icons.schema_rounded,
                          label: 'Reports',
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRouter.reports);
                          },
                        ),
                        const SizedBox(width: 10),
                        _MoreItem(
                          icon: Icons.sms_outlined,
                          label: 'SMS log',
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed(AppRouter.smsActivity);
                          },
                        ),
                        const SizedBox(width: 10),
                        _MoreItem(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Funds',
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRouter.funds);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Latest',
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
                      child: txns.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No transactions recorded yet.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.ink400,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < txns.length; i++) ...[
                                  if (i > 0)
                                    const Divider(height: 1, indent: 60),
                                  _TxRow._fromApi(
                                    state: state,
                                    txn: txns[i],
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DashboardNavBar(currentIndex: 3),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;

  const _Chip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.teal900 : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppColors.teal900 : AppColors.line,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.white : AppColors.ink600,
          ),
        ),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
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
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool positive;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _TxRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.positive,
    required this.icon,
    required this.color,
    this.onTap,
  });

  factory _TxRow._fromApi({
    required AppState state,
    required Map<String, dynamic> txn,
    VoidCallback? onTap,
  }) {
    final type = txn['type']?.toString() ?? '';
    final member = txn['member']?.toString() ?? '';
    final date = state.txnDateLabel(txn['date']);
    return _TxRow(
      title: txn['title']?.toString() ?? state.txnTypeLabel(type),
      subtitle: [member, date].where((s) => s.isNotEmpty).join(' · '),
      amount: state.amountLabel(txn),
      positive: state.isCredit(txn),
      icon: _txIcon(type),
      color: _txColor(type, state.isCredit(txn)),
      onTap: onTap,
    );
  }

  static IconData _txIcon(String type) {
    switch (type) {
      case 'loan_disbursement':
      case 'loan_repayment':
        return Icons.replay_rounded;
      case 'fine':
        return Icons.gavel_outlined;
      case 'share':
        return Icons.pie_chart_outline_rounded;
      case 'social_fund':
        return Icons.favorite_outline_rounded;
      case 'expense':
        return Icons.receipt_long_outlined;
      case 'withdrawal':
        return Icons.money_off_rounded;
      default:
        return Icons.savings_outlined;
    }
  }

  static Color _txColor(String type, bool credit) {
    switch (type) {
      case 'loan_disbursement':
        return credit ? AppColors.teal700 : AppColors.blue;
      case 'loan_repayment':
        return AppColors.teal700;
      case 'fine':
        return AppColors.danger;
      case 'share':
        return AppColors.blue;
      case 'social_fund':
        return AppColors.gold500;
      case 'expense':
      case 'withdrawal':
        return AppColors.ink600;
      default:
        return AppColors.green600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
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
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.ink400,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: positive ? AppColors.green600 : AppColors.ink900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}