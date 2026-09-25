import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x16),
              HxHeader(
                title: tr('Member Statement'),
                subtitle: _loading ? null : _fullName,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: AppSpace.x20),
              if (_loading)
                const HxSkeletonList(rows: 6)
              else if (balance == null)
                const HxEmpty(
                  icon: Icons.person_off_outlined,
                  title: 'Member not found',
                  message: 'We couldn\'t find this member\'s details.',
                )
              else ...[
                _SummaryCard(balance: balance, loansTaken: _loansTaken),
                const SizedBox(height: AppSpace.x24),
                const HxSectionTitle(title: 'Transaction history'),
                const SizedBox(height: AppSpace.x12),
                if (_transactions.isEmpty)
                  const HxEmpty(
                    icon: Icons.receipt_long_rounded,
                    title: 'No transactions yet',
                    message: 'This member hasn\'t recorded any activity yet.',
                  )
                else
                  HxSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < _transactions.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 68),
                          _TransactionRow(txn: _transactions[i]),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpace.x24),
                HxButton(
                  text: tr('Share statement'),
                  variant: HxButtonVariant.secondary,
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
              const SizedBox(height: AppSpace.x32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> balance;
  final double loansTaken;

  const _SummaryCard({
    required this.balance,
    required this.loansTaken,
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
    return HxSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KVRow(
            label: 'Member since',
            value: state.isoDate(balance['joinedAt']),
            display: DisplayMode.neutral,
          ),
          _KVRow(
            label: 'Total savings',
            value: state.money(_num(balance, 'savings')),
            display: DisplayMode.neutral,
          ),
          _KVRow(
            label: 'Total shares',
            value: state.money(_num(balance, 'shares')),
            display: DisplayMode.neutral,
          ),
          _KVRow(
            label: 'Social Fund',
            value: state.money(_num(balance, 'socialFund')),
            display: DisplayMode.neutral,
          ),
          _KVRow(
            label: 'Loans taken',
            value: state.money(loansTaken),
            display: DisplayMode.neutral,
          ),
          _KVRow(
            label: 'Loan balance',
            value: state.money(loanBalance),
            display: loanBalance > 0 ? DisplayMode.negative : DisplayMode.neutral,
          ),
          _KVRow(
            label: 'Fines',
            value: state.money(finesOutstanding),
            display: finesOutstanding > 0
                ? DisplayMode.negative
                : DisplayMode.neutral,
          ),
        ],
      ),
    );
  }
}

enum DisplayMode { neutral, negative }

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final DisplayMode display;

  const _KVRow({
    required this.label,
    required this.value,
    this.display = DisplayMode.neutral,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tr(label),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.ink400,
            ),
          ),
          HxMoney(
            text: value,
            weight: FontWeight.w600,
            fontSize: 13,
            color: display == DisplayMode.negative
                ? AppColors.negative
                : AppColors.ink900,
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
      leading: _TypeIcon(type: type),
      title: state.txnTypeLabel(type),
      subtitle: state.isoDate(txn['createdAt']),
      trailing: HxMoney.signed(
        text: state.amountLabel(txn),
        positive: state.isCredit(txn),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final String type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (type) {
      'contribution' => (AppColors.teal800, Icons.savings_outlined),
      'loan_disbursement' => (AppColors.info, Icons.account_balance_outlined),
      'loan_repayment' => (AppColors.teal700, Icons.replay_outlined),
      'fine' => (AppColors.danger, Icons.gavel_outlined),
      'social_fund' => (AppColors.gold500, Icons.people_outline),
      _ => (AppColors.ink400, Icons.receipt_long_outlined),
    };
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
}