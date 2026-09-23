import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final balance = _balance;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  ScreenBackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loading ? '' : _fullName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                          ),
                        ),
                        Text(
                          balance?['memberNumber']?.toString().isNotEmpty ==
                                  true
                              ? tr('Member #{0}', [balance!['memberNumber']])
                              : '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.ink400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.editMemberPath(widget.memberId),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.ink700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (balance == null)
                Text(
                  tr('Member not found.'),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
                )
              else ...[
                _ProfileCard(balance: balance, fullName: _fullName),
                const SizedBox(height: 20),
                Text(
                  tr('Financial position'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Savings',
                        value: state.money(_num(balance, 'savings')),
                        color: AppColors.green600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: tr('Shares {0}', [(balance['shareCount'] as num?) ?? 0]),
                        value: state.money(_num(balance, 'shares')),
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
                        value: state.money(_num(balance, 'socialFund')),
                        color: AppColors.gold500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: 'Outstanding loan',
                        value: state.money(_num(balance, 'outstanding')),
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.memberFinancialPositionPath(widget.memberId),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        Text(
                          tr('View full financial position'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.teal900,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppColors.teal900,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  tr('Recent transactions'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 12),
                if (_transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      tr('No transactions yet.'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._transactions
                      .take(3)
                      .map((tx) => _TransactionRow(txn: tx)),
                const SizedBox(height: 16),
                OutlineButton(
                  text: tr('View statement'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.memberStatementPath(widget.memberId),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static double _num(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.green600,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 2),
                Text(
                  balance['phone']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.ink400,
                  ),
                ),
                const SizedBox(height: 2),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: active ? AppColors.green100 : AppColors.line,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              tr(status),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.teal800 : AppColors.ink600,
              ),
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor(type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(type), size: 18, color: _typeColor(type)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.txnTypeLabel(type),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.isoDate(txn['createdAt']),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.ink400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            state.money((txn['amount'] as num?) ?? 0),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'contribution':
        return AppColors.green600;
      case 'loan_disbursement':
        return AppColors.blue;
      case 'loan_repayment':
        return AppColors.teal700;
      case 'fine':
        return AppColors.danger;
      case 'social_fund':
        return AppColors.gold500;
      default:
        return AppColors.ink400;
    }
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'contribution':
        return Icons.savings_outlined;
      case 'loan_disbursement':
        return Icons.account_balance_outlined;
      case 'loan_repayment':
        return Icons.replay_outlined;
      case 'fine':
        return Icons.gavel_outlined;
      case 'social_fund':
        return Icons.people_outline;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
