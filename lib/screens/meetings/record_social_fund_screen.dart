import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

class RecordSocialFundScreen extends StatefulWidget {
  const RecordSocialFundScreen({super.key, this.meetingId = '12'});

  final String meetingId;

  @override
  State<RecordSocialFundScreen> createState() =>
      _RecordSocialFundScreenState();
}

class _RecordSocialFundScreenState extends State<RecordSocialFundScreen> {
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
    _amountController.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    final state = AppState.I;
    final members = await state.fetchMembers();
    final meeting = await state.meetingById(widget.meetingId);
    final contribution = state.socialFundContribution;
    if (contribution > 0) {
      _amountController.text = contribution.toStringAsFixed(0);
    }
    if (!mounted) return;
    setState(() {
      _members = members;
      _meeting = meeting;
      _memberId = members.isNotEmpty ? members.first['id']?.toString() : null;
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

  String get _meetingTitle {
    final m = _meeting;
    if (m?['title']?.toString().isNotEmpty == true) return m!['title'].toString();
    return tr('Meeting #{0}', [m?['meetingNumber'] ?? widget.meetingId]);
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

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
    setState(() => _submitting = true);
    try {
      await AppState.I.recordTransaction(
        type: 'social_fund',
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
    final state = AppState.I;
    final before = state.groupSocialFund;
    final after = before + _amount;

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
                title: tr('Record Social Fund'),
                subtitle: _meetingTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const HxSkeletonList(rows: 6)
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
                            ),
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: tr('Amount'),
                      // The group's rules fix the social fund amount; the
                      // server refuses any other amount.
                      child: TextField(
                        key: const ValueKey('social-fund-amount'),
                        controller: _amountController,
                        readOnly: AppState.I.socialFundContribution > 0,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: tr('Enter amount'),
                          helperText: AppState.I.socialFundContribution > 0
                              ? tr('Set by the group rules')
                              : null,
                        ),
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                      _KVRow(
                        label: tr('Social Fund balance before'),
                        value: state.money(before),
                      ),
                      _KVRow(
                        label: tr('Balance after'),
                        value: state.money(after),
                        valueColor: AppColors.green600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                HxButton(
                  text: tr('Save contribution'),
                  loading: _submitting,
                  onPressed: (_submitting || _members.isEmpty) ? null : _submit,
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

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _KVRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tr(label), style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600)),
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
