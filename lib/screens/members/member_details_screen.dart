import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../i18n/i18n.dart';

class MemberDetailsScreen extends StatefulWidget {
  const MemberDetailsScreen({super.key, this.memberId = ''});

  final String memberId;

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen>
    with AutoRefreshOnPop {
  Map<String, dynamic>? _balance;
  List<Map<String, dynamic>> _transactions = [];
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
    final results = await Future.wait([
      state.fetchMemberBalances(refresh: true),
      state.fetchTransactions(refresh: true),
    ]);
    if (!mounted) return;
    setState(() {
      _balance = state.balanceFor(widget.memberId);
      _transactions = results[1]
          .where((t) => t['memberId'] == widget.memberId)
          .toList()
        ..sort((a, b) =>
            (b['createdAt']?.toString() ?? '')
                .compareTo(a['createdAt']?.toString() ?? ''));
      _loading = false;
    });
  }

  String get _fullName {
    final b = _balance;
    if (b == null) return '';
    final name = [b['firstName'], b['lastName']]
        .where((s) => (s ?? '').toString().isNotEmpty)
        .join(' ');
    return name.isEmpty ? tr('Unnamed member') : name;
  }

  static double _num(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final balance = _balance;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x16),
              HxHeader(
                title: _loading ? 'Member' : _fullName,
                subtitle: balance?['memberNumber']?.toString().isNotEmpty == true
                    ? tr('Member #{0}', [balance!['memberNumber']])
                    : null,
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  HxIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: tr('Edit'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.editMemberPath(widget.memberId),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.x20),
              if (_loading)
                _LoadingSkeleton()
              else if (balance == null)
                HxEmpty(
                  icon: Icons.person_off_outlined,
                  title: 'Member not found',
                  message: 'We couldn\'t find this member\'s details.',
                )
              else ...[
                _ProfileCard(balance: balance, fullName: _fullName),
                const SizedBox(height: AppSpace.x20),
                const HxSectionTitle(title: 'Financial position'),
                const SizedBox(height: AppSpace.x12),
                Row(
                  children: [
                    Expanded(
                      child: HxStat(
                        label: 'Savings',
                        value: state.money(_num(balance, 'savings')),
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: tr('Shares {0}',
                            [(balance['shareCount'] as num?) ?? 0]),
                        value: state.money(_num(balance, 'shares')),
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
                        value: state.money(_num(balance, 'socialFund')),
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: 'Outstanding loan',
                        value: state.money(_num(balance, 'outstanding')),
                        valueColor: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x16),
                HxSurface(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.memberFinancialPositionPath(widget.memberId),
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr('View full financial position'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.teal900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.teal900,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x24),
                const HxSectionTitle(title: 'Recent transactions'),
                const SizedBox(height: AppSpace.x12),
                if (_transactions.isEmpty)
                  HxEmpty(
                    icon: Icons.receipt_long_rounded,
                    title: 'No transactions yet',
                    message: 'This member hasn\'t recorded any activity yet.',
                  )
                else
                  HxSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                    children: [
                      for (var i = 0;
                          i < _transactions.length && i < 3;
                          i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 68),
                        _TransactionRow(txn: _transactions[i]),
                      ],
                    ],
                  ),
                  ),
                const SizedBox(height: AppSpace.x16),
                if (_transactions.isNotEmpty)
                  HxButton(
                    text: tr('View statement'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.memberStatementPath(widget.memberId),
                      );
                    },
                    variant: HxButtonVariant.secondary,
                  ),
              ],
              const SizedBox(height: AppSpace.x32),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HxSkeleton(height: 88),
        const SizedBox(height: AppSpace.x20),
        const HxSkeleton(width: 130, height: 14),
        const SizedBox(height: AppSpace.x12),
        const HxSkeletonStats(),
        const SizedBox(height: AppSpace.x12),
        const HxSkeletonStats(),
        const SizedBox(height: AppSpace.x20),
        const HxSkeleton(width: 130, height: 14),
        const SizedBox(height: AppSpace.x12),
        const HxSkeletonList(rows: 3),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> balance;
  final String fullName;
  const _ProfileCard({required this.balance, required this.fullName});

  String get _initials {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return ('$first$last').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final status = balance['status']?.toString() ?? 'Active';
    final active = status == 'Active';
    return HxSurface(
      padding: const EdgeInsets.all(AppSpace.x20),
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouter.editMemberPath(balance['id']?.toString() ?? ''),
        );
      },
      child: Row(
        children: [
          HxAvatar(initials: _initials, size: 64),
          const SizedBox(width: AppSpace.x16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  balance['phone']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.ink400,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tr('Joined {0}', [AppState.I.isoDate(balance['joinedAt'])]),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.ink400,
                  ),
                ),
              ],
            ),
          ),
          HxPill(
            text: tr(status),
            tone: active ? HxPillTone.success : HxPillTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _TransactionRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final type = txn['type']?.toString() ?? '';
    return HxRow(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouter.transactionDetailsPath(txn['id']?.toString() ?? ''),
        );
      },
      leading: _typeTile(type),
      title: state.txnTypeLabel(type),
      subtitle: state.isoDate(txn['createdAt']),
      trailing: HxMoney.signed(
        text: state.amountLabel(txn),
        positive: state.isCredit(txn),
      ),
    );
  }

  static Widget _typeTile(String type) {
    final (Color color, IconData icon) = _decor(type);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.sm,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  static (Color, IconData) _decor(String type) {
    switch (type) {
      case 'contribution':
        return (AppColors.teal800, Icons.savings_outlined);
      case 'loan_disbursement':
        return (AppColors.info, Icons.account_balance_outlined);
      case 'loan_repayment':
        return (AppColors.teal700, Icons.replay_outlined);
      case 'fine':
        return (AppColors.danger, Icons.gavel_outlined);
      case 'social_fund':
        return (AppColors.gold500, Icons.people_outline);
      default:
        return (AppColors.ink400, Icons.receipt_long_outlined);
    }
  }
}