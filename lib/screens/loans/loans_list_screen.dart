import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

class LoansListScreen extends StatefulWidget {
  const LoansListScreen({super.key});

  @override
  State<LoansListScreen> createState() => _LoansListScreenState();
}

class _LoansListScreenState extends State<LoansListScreen> {
  static const List<Color> _avatarColors = [
    AppColors.green600,
    AppColors.blue,
    AppColors.gold500,
  ];

  List<Map<String, dynamic>> _loans = [];
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
      state.fetchLoans(refresh: true),
      state.fetchMembers(),
    ]);
    if (!mounted) return;
    setState(() {
      _loans = results[0];
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

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final active = _loans.where((l) => l['status'] == 'active').toList();
    final outstanding = active.fold<double>(
      0,
      (sum, l) =>
          sum + ((l['amount'] as num? ?? 0) - (l['amountRepaid'] as num? ?? 0)),
    );
    final totalLoaned =
        _loans.fold<double>(0, (sum, l) => sum + (l['amount'] as num? ?? 0));
    final totalRepaid = _loans.fold<double>(
        0, (sum, l) => sum + (l['amountRepaid'] as num? ?? 0));

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
                    child: Text(
                      tr('Loans'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).pushNamed(
                        AppRouter.recordLoan,
                        arguments: _meetingId,
                      );
                      _load();
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(Icons.add, size: 22, color: AppColors.teal900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: tr('Active loans'),
                        value: '${active.length}',
                        color: AppColors.teal800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: tr('Outstanding'),
                        value: state.money(outstanding),
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: tr('Total loaned'),
                        value: state.money(totalLoaned),
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: tr('Total repaid'),
                        value: state.money(totalRepaid),
                        color: AppColors.green600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  tr('Recent loans'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: _loans.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            tr('No loans recorded yet.'),
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink400),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < _loans.length; i++) ...[
                              if (i > 0) const Divider(height: 1, indent: 56),
                              _LoanRow(
                                name: _memberName(_loans[i]['memberId']?.toString()),
                                initials: _initials(
                                    _memberName(_loans[i]['memberId']?.toString())),
                                amount: state.money((_loans[i]['amount'] as num?) ?? 0),
                                months: '${state.maxLoanPeriodMonths} months',
                                status: _loans[i]['status']?.toString() ?? 'active',
                                color: _avatarColors[i % _avatarColors.length],
                                onTap: () async {
                                  await Navigator.of(context).pushNamed(
                                    AppRouter.loanDetailsPath(
                                        _loans[i]['id']?.toString() ?? ''),
                                    arguments: _meetingId,
                                  );
                                  _load();
                                },
                              ),
                            ],
                          ],
                        ),
                ),
              ],
              const SizedBox(height: 24),
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
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
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

class _LoanRow extends StatelessWidget {
  final String name;
  final String initials;
  final String amount;
  final String months;
  final String status;
  final Color color;
  final VoidCallback onTap;

  const _LoanRow({
    required this.name,
    required this.initials,
    required this.amount,
    required this.months,
    required this.status,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = status == 'active';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(tr(initials), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(name), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                  const SizedBox(height: 2),
                  Text('$amount · $months', style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.green100 : AppColors.line,
                borderRadius: AppRadius.sm,
              ),
              child: Text(
                active ? tr('Active') : tr('Repaid'),
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.teal800 : AppColors.ink600),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}
