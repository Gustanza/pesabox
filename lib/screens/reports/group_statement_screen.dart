import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/i18n.dart';
import '../../services/app_data.dart';
import '../../services/report_data.dart';
import '../../services/report_service.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';

/// The group's statement: cycle progress and totals, all from live data.
class GroupStatementScreen extends StatefulWidget {
  const GroupStatementScreen({super.key, this.service, this.source});

  /// Injectable for tests; the app builds the file from live data.
  final ReportService? service;

  /// Where the figures come from. The app uses the live data with errors
  /// surfaced ([AppStateReportSource]), so a failed download shows an error
  /// instead of old or empty numbers.
  final ReportSource? source;

  @override
  State<GroupStatementScreen> createState() => _GroupStatementScreenState();
}

class _GroupStatementScreenState extends State<GroupStatementScreen>
    with AutoRefreshOnPop {
  late final ReportSource _source = widget.source ?? const AppStateReportSource();
  late final ReportService _service = widget.service ?? LocalReportService(source: _source);

  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _meetingsHeld = 0;
  Map<String, dynamic>? _group;

  /// Computed from the non-reversed transactions and non-cancelled loans
  /// (never from the group's stored running totals, which can drift).
  GroupFigures _fig = GroupFigures.compute();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onReturnedToScreen() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final group = await _source.group();
      final results = await Future.wait([
        _source.meetings(),
        _source.loans(),
        _source.transactions(),
        _source.members(),
        _source.govLoans(),
      ]);
      if (!mounted) return;
      setState(() {
        _group = group;
        _meetingsHeld = results[0].where((m) => m['status'] == 'completed').length;
        _fig = GroupFigures.compute(
          loans: results[1], // cancelled loans are skipped inside
          transactions: results[2],
          members: results[3],
          govLoans: results[4],
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Never show stale or empty figures as if they were current.
      setState(() {
        _error = tr('Could not load the data for the report: {0}', ['$e']);
        _loading = false;
      });
    }
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final file = await _service.export(
        datasets: const ['group-summary', 'loans', 'government-loans'],
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

  String _v(num n) => _loading ? '…' : (_error != null ? '—' : AppState.I.money(n));

  Widget _errorCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.danger),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger)),
            const SizedBox(height: 12),
            HxButton(
              text: tr('Try again'),
              variant: HxButtonVariant.secondary,
              onPressed: _load,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final app = AppState.I;
    final group = _group ?? app.group;
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
              AuthHeader(
                title: tr('Group Statement'),
                subtitle: (group?['name'] as String?) ?? app.groupName,
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                _errorCard(),
                const SizedBox(height: 16),
              ],
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
                        Expanded(
                          child: _InverseStat(
                            label: tr('Share value'),
                            value: app.money((group?['shareValue'] as num?) ?? app.shareValue),
                          ),
                        ),
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
                    _KVRow(label: tr('Total contributions'), value: _v(_fig.savings)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Total shares'), value: _v(_fig.shares)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Social fund'), value: _v(_fig.socialFund)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Loans disbursed'), value: _v(_fig.loansDisbursed)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Loans outstanding'), value: _v(_fig.loansOutstanding)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Loans repaid'), value: _v(_fig.loansRepaid)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Total fines'), value: _v(_fig.fines)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Government loans received'), value: _v(_fig.govReceived)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Government loans outstanding'), value: _v(_fig.govOutstanding)),
                    const Divider(height: 24),
                    _KVRow(label: tr('Total expenses'), value: _v(_fig.expenses), strong: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlineButton(
                text: _saving ? tr('Preparing…') : tr('Download statement (PDF)'),
                onPressed: (_saving || _error != null) ? null : _download,
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
