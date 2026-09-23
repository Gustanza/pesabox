import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import '../../i18n/i18n.dart';

class MemberStatementScreen extends StatefulWidget {
  const MemberStatementScreen({super.key, this.memberId = ''});

  final String memberId;

  @override
  State<MemberStatementScreen> createState() => _MemberStatementScreenState();
}

class _MemberStatementScreenState extends State<MemberStatementScreen>
    with AutoRefreshOnPop {
  Map<String, dynamic>? _balance;
  List<Map<String, dynamic>> _transactions = [];
  double _loansTaken = 0;
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
      state.fetchLoans(refresh: true),
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
      _loansTaken = results[2]
          .where((l) => l['memberId'] == widget.memberId)
          .fold<double>(0, (sum, l) => sum + _num(l, 'amount'));
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

  static double _num(Map<String, dynamic>? m, String key) {
    final v = m?[key];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
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
              AuthHeader(
                title: tr('Member Statement'),
                subtitle: _loading ? '' : _fullName,
                onBack: () => Navigator.of(context).maybePop(),
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
                _StatementSummaryCard(
                  balance: balance,
                  loansTaken: _loansTaken,
                  fullName: _fullName,
                ),
                const SizedBox(height: 20),
                Text(
                  tr('Transaction history'),
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
                  ..._transactions.map(
                    (tx) => _StatementTransactionRow(txn: tx),
                  ),
                const SizedBox(height: 20),
                OutlineButton(
                  text: tr('Share statement'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr('Statement shared via SMS')),
                        behavior: SnackBarBehavior.floating,
                      ),
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
}

class _StatementSummaryCard extends StatelessWidget {
  final Map<String, dynamic> balance;
  final double loansTaken;
  final String fullName;

  const _StatementSummaryCard({
    required this.balance,
    required this.loansTaken,
    required this.fullName,
  });

  static double _num(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final loanBalance = _num(balance, 'outstanding');
    final finesOutstanding = _num(balance, 'finesOwed');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KVRow(
            label: 'Member since',
            value: state.isoDate(balance['joinedAt']),
          ),
          _KVRow(
            label: 'Total savings',
            value: state.money(_num(balance, 'savings')),
          ),
          _KVRow(
            label: 'Total shares',
            value: state.money(_num(balance, 'shares')),
          ),
          _KVRow(
            label: 'Social Fund',
            value: state.money(_num(balance, 'socialFund')),
          ),
          _KVRow(
            label: 'Loans taken',
            value: state.money(loansTaken),
          ),
          _KVRow(
            label: 'Loan balance',
            value: state.money(loanBalance),
            valueColor: loanBalance > 0 ? AppColors.danger : AppColors.ink900,
          ),
          _KVRow(
            label: 'Fines',
            value: state.money(finesOutstanding),
            valueColor:
                finesOutstanding > 0 ? AppColors.danger : AppColors.ink900,
          ),
        ],
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _KVRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tr(label),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.ink600,
            ),
          ),
          Text(
            tr(value),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementTransactionRow extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _StatementTransactionRow({required this.txn});

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
