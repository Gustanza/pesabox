import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AuthHeader(
                title: tr('Financial Position'),
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
                _SectionCard(
                  title: 'Savings',
                  children: [
                    _KVRow(
                        label: 'Total savings',
                        value: state.money(savings)),
                    _KVRow(
                        label: 'Contributions made',
                        value: '${balance['contributionCount'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Shares',
                  children: [
                    _KVRow(label: 'Shares held', value: '$shareCount'),
                    _KVRow(
                        label: 'Share value',
                        value: state.money(shareValue)),
                    _KVRow(
                        label: 'Total share value',
                        value: state.money(_num(balance, 'shares'))),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Social Fund',
                  children: [
                    _KVRow(
                        label: 'Contributed',
                        value: state.money(_num(balance, 'socialFund'))),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Loan',
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
                      valueColor: AppColors.danger,
                    ),
                    if (loan != null && loan['dueDate'] != null)
                      _KVRow(
                        label: 'Due date',
                        value: state.isoDate(loan['dueDate']),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Fines',
                  children: [
                    _KVRow(
                        label: 'Charged', value: state.money(finesCharged)),
                    _KVRow(label: 'Paid', value: state.money(finesPaid)),
                  ],
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
          Text(
            tr(title),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
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
