import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

class RecordLoanScreen extends StatefulWidget {
  const RecordLoanScreen({super.key});

  @override
  State<RecordLoanScreen> createState() => _RecordLoanScreenState();
}

class _RecordLoanScreenState extends State<RecordLoanScreen> {
  final _amountController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  String? _memberId;
  String? _meetingId;
  String _method = 'Cash';
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _meetingId ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<void> _load() async {
    final state = AppState.I;
    final results = await Future.wait([
      state.fetchMembers(),
      state.fetchMemberBalances(),
    ]);
    if (!mounted) return;
    setState(() {
      _members = results[0];
      _memberId = _members.isNotEmpty ? _members.first['id']?.toString() : null;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _memberName(Map<String, dynamic> m) => [m['firstName'], m['lastName']]
      .where((s) => (s ?? '').toString().isNotEmpty)
      .join(' ');

  double get _amount => double.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;

  static String _rateText(double r) => r == r.roundToDouble() ? '${r.toInt()}' : '$r';

  /// The group's loan limit for the chosen member (savings + shares × the
  /// multiplier); the server enforces it.
  double _maxFor(AppState state) {
    final b = state.balanceFor(_memberId);
    num v(String k) => (b?[k] as num?) ?? 0;
    return (v('savings') + v('shares')).toDouble() * state.maxLoanMultiplier;
  }

  /// The member confirms what they will owe before the loan is issued.
  Future<bool> _confirm() async {
    final state = AppState.I;
    final p = state.loanPreview(_amount);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Confirm loan')),
        content: Text(tr('Principal {0} + interest {1} = {2} to repay over {3} months.', [
          state.money(_amount),
          state.money(p.interest),
          state.money(p.totalDue),
          state.maxLoanPeriodMonths,
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Disburse loan'))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _submit() async {
    final memberId = _memberId;
    final amount = _amount;
    if (memberId == null) {
      _showError(tr('Select a member'));
      return;
    }
    if (amount <= 0) {
      _showError(tr('Enter a valid amount'));
      return;
    }
    if (!await _confirm()) return;
    setState(() => _submitting = true);
    try {
      await AppState.I.createLoan(
        memberId: memberId,
        amount: amount,
        meetingId: _meetingId,
        method: _method,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(message)), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final savings = state.balanceFor(_memberId)?['savings'];
    final currentSavings = (savings is num) ? savings.toDouble() : 0.0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AuthHeader(title: tr('Record Loan'), subtitle: tr('Disburse a new loan.')),
              const SizedBox(height: 20),
              if (_loading)
                const HxSkeletonList(rows: 6)
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                        label: tr('Select member'),
                        child: _members.isEmpty
                            ? Text(
                                tr('No members in this group yet.'),
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink400),
                              )
                            : DropdownButtonFormField<String>(
                                initialValue: _memberId,
                                items: _members
                                    .map((m) => DropdownMenuItem(
                                          value: m['id']?.toString(),
                                          child: Text(tr(_memberName(m))),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _memberId = v),
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('Current savings: {0}', [state.money(currentSavings)]),
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: tr('Requested amount'),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              hintText: tr('Enter amount (e.g. 120,000)')),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: tr('Disbursement method'),
                        child: DropdownButtonFormField<String>(
                          initialValue: _method,
                          items: const ['Cash', 'Mobile Money', 'Bank Transfer']
                              .map((m) => DropdownMenuItem(value: m, child: Text(tr(m))))
                              .toList(),
                          onChanged: (v) => setState(() => _method = v ?? 'Cash'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.green100, borderRadius: AppRadius.md),
                  child: Column(
                    children: [
                      _EligRow(label: tr('Interest rate (flat)'), value: '${_rateText(state.loanInterestRate)}%'),
                      const Divider(height: 24, color: Color(0xFFC9E8D6)),
                      _EligRow(label: tr('Interest'), value: state.money(state.loanPreview(_amount).interest)),
                      const Divider(height: 24, color: Color(0xFFC9E8D6)),
                      _EligRow(
                        key: const ValueKey('loan-total-due'),
                        label: tr('Total to repay'),
                        value: state.money(state.loanPreview(_amount).totalDue),
                        strong: true,
                      ),
                      const Divider(height: 24, color: Color(0xFFC9E8D6)),
                      _EligRow(
                        label: tr('Repayment period'),
                        value: tr('{0} months', [state.maxLoanPeriodMonths]),
                      ),
                      if (state.maxLoanMultiplier > 0) ...[
                        const Divider(height: 24, color: Color(0xFFC9E8D6)),
                        _EligRow(
                          label: tr('Max for this member'),
                          value: state.money(_maxFor(state)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                HxButton(
                  text: tr('Disburse loan'),
                  loading: _submitting,
                  onPressed:
                      (_submitting || _members.isEmpty) ? null : _submit,
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

class _EligRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _EligRow({super.key, required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(tr(label), style: GoogleFonts.inter(fontSize: 13, color: AppColors.teal900)),
        Text(
          tr(value),
          style: GoogleFonts.inter(
            fontSize: strong ? 16 : 13,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.teal900,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(label), style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink700)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
