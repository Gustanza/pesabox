import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

class RecordContributionScreen extends StatefulWidget {
  const RecordContributionScreen({super.key, this.meetingId = '12'});

  final String meetingId;

  @override
  State<RecordContributionScreen> createState() =>
      _RecordContributionScreenState();
}

class _RecordContributionScreenState extends State<RecordContributionScreen> {
  final _amountController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic>? _meeting;
  String? _memberId;
  String _method = 'Cash';
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = AppState.I;
    final members = await state.fetchMembers();
    final meeting = await state.meetingById(widget.meetingId);
    final mandatory = state.mandatorySavingsAmount;
    if (mandatory > 0) {
      _amountController.text = mandatory.toStringAsFixed(0);
    }
    if (!mounted) return;
    setState(() {
      _members = members;
      _meeting = meeting;
      _memberId = members.isNotEmpty ? members.first['id']?.toString() : null;
      _loading = false;
    });
  }

  String get _meetingTitle {
    final m = _meeting;
    if (m?['title']?.toString().isNotEmpty == true) return m!['title'].toString();
    return tr('Meeting #{0}', [m?['meetingNumber'] ?? widget.meetingId]);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _memberName(Map<String, dynamic> m) => [m['firstName'], m['lastName']]
      .where((s) => (s ?? '').toString().isNotEmpty)
      .join(' ');

  Future<void> _submit() async {
    final memberId = _memberId;
    final amount = double.tryParse(_amountController.text.trim());
    if (memberId == null) {
      _showError(tr('Select a member'));
      return;
    }
    if (amount == null || amount <= 0) {
      _showError(tr('Enter a valid amount'));
      return;
    }
    setState(() => _submitting = true);
    try {
      await AppState.I.recordTransaction(
        type: 'contribution',
        memberId: memberId,
        meetingId: widget.meetingId,
        amount: amount,
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
    final mandatory = AppState.I.mandatorySavingsAmount;

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
                title: tr('Record Contribution'),
                subtitle: _meetingTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _SectionCard(
                  title: tr('Contribution details'),
                  children: [
                    _Field(
                      label: tr('Member'),
                      child: _members.isEmpty
                          ? Text(
                              tr('No members in this group yet.'),
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.ink400),
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
                              decoration: _inputDecoration(),
                            ),
                    ),
                    if (mandatory > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        tr('Mandatory savings: {0} per meeting', [AppState.I.money(mandatory)]),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.ink400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _Field(
                      label: tr('Amount'),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration:
                            _inputDecoration(hint: tr('Enter amount')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: tr('Payment method'),
                      child: DropdownButtonFormField<String>(
                        initialValue: _method,
                        items: const ['Cash', 'Mobile Money', 'Bank Transfer']
                            .map((m) => DropdownMenuItem(value: m, child: Text(tr(m))))
                            .toList(),
                        onChanged: (v) => setState(() => _method = v ?? 'Cash'),
                        decoration: _inputDecoration(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
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
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white),
                          )
                        : Text(
                            tr('Save contribution'),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
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
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(title),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
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
        Text(
          tr(label),
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
