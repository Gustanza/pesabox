import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class RecordLoanRepaymentScreen extends StatefulWidget {
  const RecordLoanRepaymentScreen({super.key, this.loanId = 'l3'});

  final String loanId;

  @override
  State<RecordLoanRepaymentScreen> createState() =>
      _RecordLoanRepaymentScreenState();
}

class _RecordLoanRepaymentScreenState extends State<RecordLoanRepaymentScreen> {
  final _amountController = TextEditingController();
  Map<String, dynamic>? _loan;
  Map<String, dynamic>? _member;
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
    final loan = await state.loanById(widget.loanId);
    final member = await state.memberById(loan?['memberId']?.toString());
    if (!mounted) return;
    setState(() {
      _loan = loan;
      _member = member;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  double get _outstanding {
    final loan = _loan;
    if (loan == null) return 0;
    return ((loan['amount'] as num? ?? 0) - (loan['amountRepaid'] as num? ?? 0))
        .toDouble();
  }

  String get _memberName {
    final m = _member;
    if (m == null) return 'Unknown member';
    final name = [m['firstName'], m['lastName']]
        .where((s) => (s ?? '').toString().isNotEmpty)
        .join(' ');
    return name.isEmpty ? 'Unknown member' : name;
  }

  String get _initials {
    final parts = _memberName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return ('$first$last').toUpperCase();
  }

  Future<void> _submit() async {
    final amount = _amount;
    if (amount <= 0) {
      _showError('Enter a valid amount');
      return;
    }
    if (amount > _outstanding) {
      _showError('Repayment exceeds the remaining balance');
      return;
    }
    setState(() => _submitting = true);
    try {
      await AppState.I.repayLoan(
        widget.loanId,
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
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final after = (_outstanding - _amount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const AuthHeader(title: 'Record Repayment'),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loan == null)
                Text(
                  'Loan not found.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
                )
              else ...[
                _AvatarCard(name: _memberName, initials: _initials, outstanding: state.money(_outstanding)),
                const SizedBox(height: 16),
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
                        label: 'Amount paid',
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(hint: state.money(_outstanding)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Payment method',
                        child: DropdownButtonFormField<String>(
                          initialValue: _method,
                          items: const ['Cash', 'Mobile Money', 'Bank Transfer']
                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (v) => setState(() => _method = v ?? 'Cash'),
                          decoration: _inputDecoration(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                      _KVRow(label: 'Balance before', value: state.money(_outstanding)),
                      const Divider(height: 24),
                      _KVRow(label: 'Balance after', value: state.money(after), strong: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green600,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : Text(
                            'Save repayment',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white),
                          ),
                  ),
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

InputDecoration _inputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.teal900, width: 1.5),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
    ),
  );
}

class _AvatarCard extends StatelessWidget {
  final String name;
  final String initials;
  final String outstanding;

  const _AvatarCard({required this.name, required this.initials, required this.outstanding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.green600, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(initials, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                const SizedBox(height: 2),
                Text('Outstanding: $outstanding', style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400)),
              ],
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
  final bool strong;

  const _KVRow({required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: strong ? 16 : 13,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.ink900,
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
        Text(label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink700)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
