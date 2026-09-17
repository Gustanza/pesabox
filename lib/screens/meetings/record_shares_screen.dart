import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class RecordSharesScreen extends StatefulWidget {
  const RecordSharesScreen({super.key, this.meetingId = '12'});

  final String meetingId;

  @override
  State<RecordSharesScreen> createState() => _RecordSharesScreenState();
}

class _RecordSharesScreenState extends State<RecordSharesScreen> {
  final _sharesController = TextEditingController();
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
    _sharesController.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    final state = AppState.I;
    final results = await Future.wait([
      state.fetchMembers(),
      state.meetingById(widget.meetingId),
      state.fetchMemberBalances(),
    ]);
    if (!mounted) return;
    final members = results[0] as List<Map<String, dynamic>>;
    setState(() {
      _members = members;
      _meeting = results[1] as Map<String, dynamic>?;
      _memberId = members.isNotEmpty ? members.first['id']?.toString() : null;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _sharesController.dispose();
    super.dispose();
  }

  String _memberName(Map<String, dynamic> m) => [m['firstName'], m['lastName']]
      .where((s) => (s ?? '').toString().isNotEmpty)
      .join(' ');

  String get _meetingTitle {
    final m = _meeting;
    if (m?['title']?.toString().isNotEmpty == true) return m!['title'].toString();
    return 'Meeting #${m?['meetingNumber'] ?? widget.meetingId}';
  }

  int get _shareCount => int.tryParse(_sharesController.text.trim()) ?? 0;

  int get _currentShares =>
      (AppState.I.balanceFor(_memberId)?['shareCount'] as num?)?.toInt() ?? 0;

  Future<void> _submit() async {
    final memberId = _memberId;
    final count = _shareCount;
    if (memberId == null) {
      _showError('Select a member');
      return;
    }
    if (count <= 0) {
      _showError('Enter the number of shares purchased');
      return;
    }
    setState(() => _submitting = true);
    try {
      await AppState.I.recordTransaction(
        type: 'share',
        memberId: memberId,
        meetingId: widget.meetingId,
        shareCount: count,
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
    final shareValue = state.shareValue;
    final totalValue = _shareCount * shareValue;

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
                title: 'Record Shares',
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
                  title: 'Shares details',
                  children: [
                    _Field(
                      label: 'Member',
                      child: _members.isEmpty
                          ? Text(
                              'No members in this group yet.',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.ink400),
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
                      label: 'Shares purchased (min ${state.minShares}, max ${state.maxShares} per meeting)',
                      child: TextField(
                        controller: _sharesController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(hint: 'Enter number of shares'),
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
                      _KVRow(label: 'Share value', value: state.money(shareValue)),
                      _KVRow(label: 'Total value', value: state.money(totalValue)),
                      _KVRow(
                        label: 'New cumulative',
                        value: '${_currentShares + _shareCount} shares',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                            'Save shares',
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
            title,
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

  const _KVRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600)),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
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
          label,
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
