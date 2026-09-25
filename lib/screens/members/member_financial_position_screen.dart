import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../i18n/i18n.dart';

class MemberFinancialPositionScreen extends StatefulWidget {
  const MemberFinancialPositionScreen({super.key, this.memberId = ''});

  final String memberId;

  @override
  State<MemberFinancialPositionScreen> createState() =>
      _MemberFinancialPositionScreenState();
}

class _MemberFinancialPositionScreenState
    extends State<MemberFinancialPositionScreen> with AutoRefreshOnPop {
  Map<String, dynamic>? _balance;
  Map<String, dynamic>? _activeLoan;
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
      state.fetchLoans(refresh: true),
    ]);
    if (!mounted) return;
    final loans = results[1];
    setState(() {
      _balance = state.balanceFor(widget.memberId);
      _activeLoan = loans.cast<Map<String, dynamic>?>().firstWhere(
            (l) => l?['memberId'] == widget.memberId && l?['status'] == 'active',
            orElse: () => null,
          );
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
    final state = AppState.I;
    final balance = _balance;
    final loan = _activeLoan;

    final finesCharged = _num(balance, 'finesCharged');
    final finesPaid = _num(balance, 'finesPaid');
    final shareValue = state.shareValue;
    final shareCount = (balance?['shareCount'] as num?) ?? 0;
    final savings = _num(balance, 'savings');

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
                title: tr('Financial Position'),
                subtitle: _loading ? null : _fullName,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: AppSpace.x20),
              if (_loading)
                const _LoadingSkeleton()
              else if (balance == null)
                const HxEmpty(
                  icon: Icons.person_off_outlined,
                  title: 'Member not found',
                  message: 'We couldn\'t find this member\'s details.',
                )
              else ...[
                const HxSectionTitle(title: 'Savings'),
                const SizedBox(height: AppSpace.x12),
                HxSurface(
                  child: Column(
                    children: [
                      _KVRow(
                          label: 'Total savings',
                          value: state.money(savings)),
                      _KVRow(
                          label: 'Contributions made',
                          value: '${balance['contributionCount'] ?? 0}'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x16),
                const HxSectionTitle(title: 'Shares'),
                const SizedBox(height: AppSpace.x12),
                HxSurface(
                  child: Column(
                    children: [
                      _KVRow(label: 'Shares held', value: '$shareCount'),
                      _KVRow(label: 'Share value', value: state.money(shareValue)),
                      _KVRow(
                          label: 'Total share value',
                          value: state.money(_num(balance, 'shares'))),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x16),
                const HxSectionTitle(title: 'Social Fund'),
                const SizedBox(height: AppSpace.x12),
                HxSurface(
                  child: Column(
                    children: [
                      _KVRow(
                          label: 'Contributed',
                          value: state.money(_num(balance, 'socialFund'))),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x16),
                const HxSectionTitle(title: 'Loan'),
                const SizedBox(height: AppSpace.x12),
                HxSurface(
                  child: Column(
                    children: [
                      _KVRow(
                        label: 'Principal',
                        value: loan != null
                            ? state.money(_num(loan, 'amount'))
                            : state.money(0),
                      ),
                      _KVRow(
                        label: 'Repaid',
                        value: loan != null
                            ? state.money(_num(loan, 'amountRepaid'))
                            : state.money(0),
                      ),
                      _KVRow(
                        label: 'Outstanding',
                        value: state.money(_num(balance, 'outstanding')),
                        negative: _num(balance, 'outstanding') > 0,
                      ),
                      if (loan != null && loan['dueDate'] != null)
                        _KVRow(
                          label: 'Due date',
                          value: state.isoDate(loan['dueDate']),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x16),
                const HxSectionTitle(title: 'Fines'),
                const SizedBox(height: AppSpace.x12),
                HxSurface(
                  child: Column(
                    children: [
                      _KVRow(
                          label: 'Charged',
                          value: state.money(finesCharged)),
                      _KVRow(
                          label: 'Paid',
                          value: state.money(finesPaid)),
                    ],
                  ),
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
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HxSkeleton(width: 130, height: 14),
        SizedBox(height: AppSpace.x12),
        HxSkeleton(height: 110),
        SizedBox(height: AppSpace.x16),
        HxSkeleton(width: 130, height: 14),
        SizedBox(height: AppSpace.x12),
        HxSkeleton(height: 140),
        SizedBox(height: AppSpace.x16),
        HxSkeleton(width: 130, height: 14),
        SizedBox(height: AppSpace.x12),
        HxSkeleton(height: 70),
      ],
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final bool negative;

  const _KVRow({
    required this.label,
    required this.value,
    this.negative = false,
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
            color: negative ? AppColors.negative : AppColors.ink900,
          ),
        ],
      ),
    );
  }
}