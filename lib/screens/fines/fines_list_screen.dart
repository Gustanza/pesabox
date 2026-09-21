import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

class FinesListScreen extends StatefulWidget {
  const FinesListScreen({super.key});

  @override
  State<FinesListScreen> createState() => _FinesListScreenState();
}

class _FinesListScreenState extends State<FinesListScreen> {
  List<Map<String, dynamic>> _fines = [];
  bool _loading = true;
  String? _meetingId;

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
    final results = await Future.wait([
      state.fetchFines(refresh: true),
      state.fetchMembers(),
    ]);
    if (!mounted) return;
    setState(() {
      _fines = results[0];
      _loading = false;
    });
  }

  String _memberName(String? memberId) {
    final m = AppState.I.members.firstWhere(
      (m) => m['id'] == memberId,
      orElse: () => const {},
    );
    final name = [m['firstName'], m['lastName']]
        .where((s) => (s ?? '').toString().isNotEmpty)
        .join(' ');
    return name.isEmpty ? tr('Unknown member') : name;
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return ('$first$last').toUpperCase();
  }

  Future<void> _pay(Map<String, dynamic> fine) async {
    final amount = (fine['amount'] as num?)?.toDouble() ?? 0;
    final paid = (fine['amountPaid'] as num?)?.toDouble() ?? 0;
    final remaining = amount - paid;
    final controller = TextEditingController(text: remaining.toStringAsFixed(0));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Pay fine')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr('Amount paid')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('Pay'))),
        ],
      ),
    );
    if (confirmed != true) return;
    final amountPaid = double.tryParse(controller.text.trim()) ?? 0;
    if (amountPaid <= 0) return;
    try {
      await AppState.I.payFine(
        fine['id']?.toString() ?? '',
        amount: amountPaid,
        meetingId: _meetingId,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(e.toString())), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final total = _fines.fold<double>(0, (sum, f) => sum + (f['amount'] as num? ?? 0));
    final unpaid = _fines.fold<double>(
      0,
      (sum, f) => sum + (((f['amount'] as num? ?? 0) - (f['amountPaid'] as num? ?? 0))),
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  const ScreenBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tr('Fines'), style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).pushNamed(AppRouter.recordFine, arguments: _meetingId);
                      _load();
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                      child: const Icon(Icons.add, size: 22, color: AppColors.teal900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
              else ...[
                Row(
                  children: [
                    Expanded(child: _StatBox(label: tr('Total fines'), value: state.money(total), color: AppColors.teal800)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBox(label: tr('Unpaid'), value: state.money(unpaid), color: AppColors.danger)),
                  ],
                ),
                const SizedBox(height: 24),
                Text(tr('Recent fines'), style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.md, border: Border.all(color: AppColors.line)),
                  child: _fines.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(tr('No fines recorded yet.'), style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink400)),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < _fines.length; i++) ...[
                              if (i > 0) const Divider(height: 1, indent: 56),
                              _FineRow(
                                name: _memberName(_fines[i]['memberId']?.toString()),
                                initials: _initials(_memberName(_fines[i]['memberId']?.toString())),
                                reason: _fines[i]['reason']?.toString() ?? '',
                                amount: state.money((_fines[i]['amount'] as num?) ?? 0),
                                status: _fines[i]['status']?.toString() ?? 'pending',
                                onTap: _fines[i]['status'] == 'paid' ? null : () => _pay(_fines[i]),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
              const SizedBox(height: 24),
              if (!_loading)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(AppRouter.recordFine, arguments: _meetingId);
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green600,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                    ),
                    child: Text(tr('Record a fine'), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white)),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.md, border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(label), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.ink400)),
          const SizedBox(height: 6),
          Text(tr(value), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _FineRow extends StatelessWidget {
  final String name;
  final String initials;
  final String reason;
  final String amount;
  final String status;
  final VoidCallback? onTap;

  const _FineRow({
    required this.name,
    required this.initials,
    required this.reason,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final paid = status == 'paid';
    final waived = status == 'waived';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: paid ? AppColors.green100 : AppColors.danger100),
              alignment: Alignment.center,
              child: Text(tr(initials), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: paid ? AppColors.teal800 : AppColors.danger)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(name), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                  const SizedBox(height: 2),
                  Text('$reason · $amount', style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: paid ? AppColors.green100 : AppColors.danger100, borderRadius: AppRadius.sm),
              child: Text(
                waived ? tr('Waived') : (paid ? 'Paid' : 'Unpaid'),
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: paid ? AppColors.teal800 : AppColors.danger),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
            ],
          ],
        ),
      ),
    );
  }
}
