import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../dashboard/dashboard_nav_bar.dart';

import '../../i18n/i18n.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  static const List<String> _chips = ['All', 'Savings', 'Shares', 'Loans', 'Fines', 'Expenses'];

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen>
    with AutoRefreshOnPop {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  int _selected = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onReturnedToScreen() => _load();

  Future<void> _load() async {
    final list = await AppState.I.fetchTransactions(refresh: true);
    if (mounted) {
      setState(() {
        _transactions = list;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visible {
    var txns = _transactions;
    // Semantic filter buckets (mirror the dashboard's feature mental model,
    // not the raw schema).
    switch (_selected) {
      case 1: // Savings
        txns = txns.where((t) => t['type'] == 'contribution').toList();
      case 2: // Shares
        txns = txns.where((t) => t['type'] == 'share').toList();
      case 3: // Loans
        txns = txns
            .where((t) =>
                t['type'] == 'loan_disbursement' ||
                t['type'] == 'loan_repayment')
            .toList();
      case 4: // Fines
        txns = txns.where((t) => t['type'] == 'fine').toList();
      case 5: // Expenses
        txns = txns
            .where((t) =>
                t['type'] == 'expense' ||
                t['type'] == 'withdrawal' ||
                t['type'] == 'social_fund')
            .toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final state = AppState.I;
      txns = txns.where((t) {
        final member = t['fullName']?.toString() ??
            t['memberName']?.toString() ??
            '';
        return member.toLowerCase().contains(q) ||
            state.txnTypeLabel(t['type']?.toString() ?? '')
                .toLowerCase()
                .contains(q);
      }).toList();
    }
    return txns;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x16, 20, 0),
              child: Row(
                children: [
                  const Expanded(child: HxPageTitle(title: 'Activity')),
                  HxIconButton(
                    icon: Icons.search_rounded,
                    tooltip: tr('Search'),
                    onPressed: _query.isEmpty
                        ? null
                        : () => setState(() => _query = ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
              child: TextField(
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink900),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: tr('Search transactions...'),
                  isDense: true,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.ink400,
                    size: 20,
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.x12),
            SizedBox(
              height: 34,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
                scrollDirection: Axis.horizontal,
                itemCount: TransactionsListScreen._chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = TransactionsListScreen._chips[index];
                  return HxChip(
                    label: tr(label),
                    selected: index == _selected,
                    onTap: () => setState(() => _selected = index),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpace.x16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTransactions(visible),
                    const SizedBox(height: AppSpace.x24),
                    const HxSectionTitle(title: 'More'),
                    const SizedBox(height: AppSpace.x12),
                    Row(
                      children: [
                        _MoreItem(
                          icon: Icons.schema_rounded,
                          label: tr('Reports'),
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed(AppRouter.reports);
                          },
                        ),
                        const SizedBox(width: AppSpace.x12),
                        _MoreItem(
                          icon: Icons.sms_outlined,
                          label: tr('SMS log'),
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed(AppRouter.smsActivity);
                          },
                        ),
                        const SizedBox(width: AppSpace.x12),
                        _MoreItem(
                          icon: Icons.account_balance_wallet_outlined,
                          label: tr('Funds'),
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRouter.funds);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x24),
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

  Widget _buildTransactions(List<Map<String, dynamic>> visible) {
    final state = AppState.I;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HxSectionTitle(title: 'Latest'),
          ],
        ),
        const SizedBox(height: AppSpace.x12),
        if (_loading)
          const HxSkeletonList(rows: 5)
        else if (visible.isEmpty)
          HxEmpty(
            icon: Icons.receipt_long_rounded,
            title: 'No transactions yet',
            message: _selected == 0
                ? 'Record your first contribution to get started.'
                : 'No ${TransactionsListScreen._chips[_selected].toLowerCase()} transactions yet.',
          )
        else
          HxSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 68),
                  HxRow(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.transactionDetailsPath(
                          visible[i]['id']?.toString() ?? '',
                        ),
                      );
                    },
                    leading: _TxIcon(type: visible[i]['type']?.toString() ?? ''),
                    title: state.txnTypeLabel(
                        visible[i]['type']?.toString() ?? ''),
                    subtitle: [
                      visible[i]['fullName']?.toString() ??
                          visible[i]['memberName']?.toString() ??
                          '',
                      state.isoDate(visible[i]['createdAt']),
                    ]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    trailing: HxMoney.signed(
                      text: state.amountLabel(visible[i]),
                      positive: state.isCredit(visible[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TxIcon extends StatelessWidget {
  final String type;
  const _TxIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'loan_disbursement' => AppColors.info,
      'loan_repayment' => AppColors.teal700,
      'fine' => AppColors.danger,
      'share' => AppColors.gold500,
      'social_fund' => AppColors.gold500,
      'expense' || 'withdrawal' => AppColors.ink600,
      _ => AppColors.teal800,
    };
    final icon = switch (type) {
      'loan_disbursement' || 'loan_repayment' => Icons.replay_rounded,
      'fine' => Icons.gavel_outlined,
      'share' => Icons.pie_chart_outline_rounded,
      'social_fund' => Icons.favorite_outline_rounded,
      'expense' => Icons.receipt_long_outlined,
      'withdrawal' => Icons.money_off_rounded,
      _ => Icons.savings_outlined,
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
      ),
      child: Icon(icon, size: 20, color: color),
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
      child: Pressable(
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