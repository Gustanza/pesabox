import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class RecordFineScreen extends StatefulWidget {
  const RecordFineScreen({super.key});

  @override
  State<RecordFineScreen> createState() => _RecordFineScreenState();
}

class _RecordFineScreenState extends State<RecordFineScreen> {
  final _amountController = TextEditingController();
  final _otherReasonController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _reasons = [];
  String? _memberId;
  String? _reason;
  String? _meetingId;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _meetingId ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<void> _load() async {
    final state = AppState.I;
    final members = await state.fetchMembers();
    final reasons = state.fineReasons;
    if (!mounted) return;
    setState(() {
      _members = members;
      _reasons = reasons;
      _memberId = members.isNotEmpty ? members.first['id']?.toString() : null;
      _reason = reasons.isNotEmpty ? reasons.first['reason']?.toString() : null;
      _amountController.text = _amountFor(_reason);
      _loading = false;
    });
  }

  String _amountFor(String? reason) {
    final match = _reasons.firstWhere(
      (r) => r['reason'] == reason,
      orElse: () => const {},
    );
    final amount = (match['amount'] as num?) ?? 0;
    return amount > 0 ? amount.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  String _memberName(Map<String, dynamic> m) => [m['firstName'], m['lastName']]
      .where((s) => (s ?? '').toString().isNotEmpty)
      .join(' ');

  bool get _isOther => _reason == 'Other';

  Future<void> _submit() async {
    final memberId = _memberId;
    final reason = _isOther ? _otherReasonController.text.trim() : _reason;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (memberId == null) {
      _showError('Select a member');
      return;
    }
    if (reason == null || reason.isEmpty) {
      _showError(_isOther ? 'Describe the reason for this fine' : 'Select a fine type');
      return;
    }
    if (amount <= 0) {
      _showError('Enter a valid amount');
      return;
    }
    setState(() => _submitting = true);
    try {
      await AppState.I.createFine(
        memberId: memberId,
        reason: reason,
        amount: amount,
        meetingId: _meetingId,
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const AuthHeader(title: 'Record Fine'),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
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
                        label: 'Select member',
                        child: _members.isEmpty
                            ? Text(
                                'No members in this group yet.',
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink400),
                              )
                            : DropdownButtonFormField<String>(
                                initialValue: _memberId,
                                items: _members
                                    .map((m) => DropdownMenuItem(
                                          value: m['id']?.toString(),
                                          child: Text(_memberName(m)),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _memberId = v),
                                decoration: _inputDecoration(),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Fine type',
                        child: DropdownButtonFormField<String>(
                          initialValue: _reason,
                          items: _reasons
                              .map((r) => DropdownMenuItem(
                                    value: r['reason']?.toString(),
                                    child: Text(r['reason']?.toString() ?? ''),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _reason = v;
                            _amountController.text = _amountFor(v);
                          }),
                          decoration: _inputDecoration(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Amount',
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(hint: '1,000'),
                        ),
                      ),
                      if (_isOther) ...[
                        const SizedBox(height: 16),
                        _Field(
                          label: 'Reason',
                          child: TextField(
                            controller: _otherReasonController,
                            decoration: _inputDecoration(hint: 'Describe the reason'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_submitting || _members.isEmpty) ? null : _submit,
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
                            'Record fine',
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
