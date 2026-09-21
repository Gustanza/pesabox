import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/i18n.dart';
import '../../services/app_data.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

/// The group's statement: cycle progress and totals, all from live data.
class GroupStatementScreen extends StatefulWidget {
  const GroupStatementScreen({super.key, this.service});

  /// Injectable for tests; the app builds the file from live data.
  final ReportService? service;

  @override
  State<GroupStatementScreen> createState() => _GroupStatementScreenState();
}

class _GroupStatementScreenState extends State<GroupStatementScreen> {
  late final ReportService _service = widget.service ?? LocalReportService();

  bool _loading = true;
  bool _saving = false;
  int _meetingsHeld = 0;
  double _loansDisbursed = 0;
  double _loansRepaid = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = AppState.I;
    // each fetch keeps its cached value if the server call fails
    await app.fetchGroup(refresh: true);
    final meetings = await app.fetchMeetings(refresh: true);
    final loans = await app.fetchLoans(refresh: true);
    if (!mounted) return;
    double sum(String k) => loans.fold<double>(
        0, (s, l) => s + (l[k] is num ? (l[k] as num).toDouble() : 0));
    setState(() {
      _meetingsHeld = meetings.where((m) => m['status'] == 'completed').length;
      _loansDisbursed = sum('amount');
      _loansRepaid = sum('amountRepaid');
      _loading = false;
    });
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final file = await _service.export(
        datasets: const ['group-summary', 'loans'],
        columns: const {},
        format: 'pdf',
      );
      final path = await _service.saveAndOpen(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Saved to {0}', [path])), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.I;
    final group = app.group;
    final cycle = (group?['cycleCurrent'] as num?)?.toInt();
    final cycleTotal = (group?['cycleTotal'] as num?)?.toInt();
    final held = cycleTotal != null && cycleTotal > 0
        ? '$_meetingsHeld / $cycleTotal'
        : '$_meetingsHeld';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AuthHeader(title: tr('Group Statement'), subtitle: app.groupName),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.teal900, AppColors.teal800],
                  ),
                  borderRadius: AppRadius.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycle == null ? tr('CYCLE') : tr('CYCLE {0}', [cycle]),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _InverseStat(label: tr('Meetings held'), value: _loading ? '…' : held)),
                        const SizedBox(width: 10),
                        Expanded(child: _InverseStat(label: tr('Share value'), value: app.money(app.shareValue))),
                      ],
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
                    _KVRow(label: tr('Total contributions'), value: app.money(app.groupSavings)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Total shares'), value: app.money(app.groupShares)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Social fund'), value: app.money(app.groupSocialFund)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Loans disbursed'), value: _loading ? '…' : app.money(_loansDisbursed)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Loans outstanding'), value: app.money(app.groupLoansOut)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Loans repaid'), value: _loading ? '…' : app.money(_loansRepaid)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Total fines'), value: app.money(app.groupFines)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Total expenses'), value: app.money(app.groupExpenses), strong: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlineButton(
                text: _saving ? tr('Preparing…') : tr('Download statement (PDF)'),
                onPressed: _saving ? null : _download,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _InverseStat extends StatelessWidget {
  final String label;
  final String value;

  const _InverseStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white),
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
        // The label takes the leftover space and wraps, so a long Swahili label
        // next to a big amount can never overflow the row.
        Expanded(
          child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600)),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: strong ? 15 : 13,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.ink900,
          ),
        ),
      ],
    );
  }
}
