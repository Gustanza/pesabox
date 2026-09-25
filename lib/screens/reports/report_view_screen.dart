import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/i18n.dart';
import '../../services/app_data.dart';
import '../../services/report_data.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';

/// A live report: the group's real data for one dataset (Savings, Loans,
/// Fines, ...), an optional date range, totals, and PDF / Excel / CSV download
/// of exactly what is shown.
class ReportViewScreen extends StatefulWidget {
  const ReportViewScreen({super.key, required this.defKey, this.source, this.service});

  final String defKey;

  /// Injectable for tests; the app uses the live data.
  final ReportSource? source;
  final ReportService? service;

  @override
  State<ReportViewScreen> createState() => _ReportViewScreenState();
}

class _ReportViewScreenState extends State<ReportViewScreen> {
  static const _shownRows = 200;
  static const _moneyColumns = [
    'Amount', 'Principal', 'Interest', 'Repaid', 'Balance', 'Paid', 'Charged', 'Outstanding', 'Total Due',
  ];

  late final ReportDef _def = reportDefFor(widget.defKey)!;
  late final ReportSource _source = widget.source ?? const AppStateReportSource();
  late final ReportService _service =
      widget.service ?? LocalReportService(source: _source);

  List<Map<String, Object?>> _rows = [];
  DateTime? _from;
  DateTime? _to;
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _def.rows(_source, ReportRange(from: _from, to: _to));
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Never keep showing the previous rows as if they were current.
        _rows = [];
        _error = tr('Could not load the data for the report: {0}', ['$e']);
        _loading = false;
      });
    }
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool from}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() => from ? _from = picked : _to = picked);
    _load();
  }

  Future<void> _export(String format) async {
    if (_exporting) return;
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final file = await _service.export(
        datasets: [_def.key],
        columns: const {},
        format: format,
        from: _from == null ? '' : _iso(_from!),
        to: _to == null ? '' : _iso(_to!),
      );
      final path = await _service.saveAndOpen(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Saved to {0}', [path]))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Sum of each money column present in this dataset (rows flagged
  /// [kNoTotals], e.g. cancelled loans, are left out). A mixed list of
  /// transactions shows money in and money out separately instead of one
  /// meaningless sum.
  Map<String, num> get _totals {
    final rows = _rows.where((r) => r[kNoTotals] != true);
    num sum(String c, [bool Function(Map<String, Object?>)? keep]) => rows
        .where((r) => keep == null || keep(r))
        .fold<num>(0, (s, r) => s + (r[c] is num ? r[c] as num : 0));
    if (_def.splitByDirection) {
      return {
        tr('Money in'): sum('Amount', (r) => r['Direction'] == 'in'),
        tr('Money out'): sum('Amount', (r) => r['Direction'] == 'out'),
      };
    }
    return {for (final c in _def.columns.where(_moneyColumns.contains)) columnLabel(c): sum(c)};
  }

  @override
  Widget build(BuildContext context) {
    final title = I18n.isSwahili ? _def.sw : _def.en;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AuthHeader(title: title),
            ),
            Expanded(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpace.x20),
                      child: HxSkeletonList(rows: 8),
                    )
                  : RefreshIndicator(onRefresh: _load, child: _content()),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  for (final f in const [('pdf', 'PDF'), ('xlsx', 'Excel'), ('csv', 'CSV')]) ...[
                    if (f.$1 != 'pdf') const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_exporting || _loading) ? null : () => _export(f.$1),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(f.$2),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.teal900,
                          side: const BorderSide(color: AppColors.teal900),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final totals = _totals;
    final single = _def.key == 'group-summary' && _rows.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        if (!single) ...[
          Row(
            children: [
              Expanded(child: _dateButton(tr('From'), _from, () => _pickDate(from: true), () {
                setState(() => _from = null);
                _load();
              })),
              const SizedBox(width: 10),
              Expanded(child: _dateButton(tr('To'), _to, () => _pickDate(from: false), () {
                setState(() => _to = null);
                _load();
              })),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat(tr('Rows'), '${_rows.length}'),
              for (final e in totals.entries) _stat(e.key, AppState.I.money(e.value)),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_error != null) ...[
          Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger)),
          const SizedBox(height: 12),
        ],
        if (_rows.isEmpty && _error == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                tr('No data for these filters.'),
                style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.ink400),
              ),
            ),
          )
        else if (single)
          _summaryCard(_rows.first)
        else if (_rows.isNotEmpty)
          _table(),
      ],
    );
  }

  Widget _stat(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink400)),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink900),
            ),
          ],
        ),
      );

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap, VoidCallback onClear) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink400)),
                  Text(
                    value == null ? tr('Any') : _iso(value),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink900),
                  ),
                ],
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 18, color: AppColors.ink400),
              ),
          ],
        ),
      ),
    );
  }

  /// Group summary is one row of totals — shown as a list, not a table.
  Widget _summaryCard(Map<String, Object?> row) {
    final money = const {
      'Savings', 'Shares', 'Social Fund', 'Loans Outstanding', 'Fines Collected', 'Expenses', 'Government Loans',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _def.columns.length; i++) ...[
            if (i > 0) const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(columnLabel(_def.columns[i]), style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600)),
                Text(
                  money.contains(_def.columns[i]) && row[_def.columns[i]] is num
                      ? AppState.I.money(row[_def.columns[i]] as num)
                      : cellText(_def.columns[i], row[_def.columns[i]]),
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _table() {
    final shown = _rows.take(_shownRows).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.line),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 44,
              columnSpacing: 22,
              headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink900),
              dataTextStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.ink900),
              columns: [
                for (final c in _def.columns)
                  DataColumn(label: Text(columnLabel(c)), numeric: _moneyColumns.contains(c)),
              ],
              rows: [
                for (final r in shown)
                  DataRow(cells: [
                    for (final c in _def.columns) DataCell(Text(cellText(c, r[c]))),
                  ]),
              ],
            ),
          ),
        ),
        if (_rows.length > shown.length) ...[
          const SizedBox(height: 8),
          Text(
            tr('Showing the first {0} of {1} rows — download for all of them.', [shown.length, _rows.length]),
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400),
          ),
        ],
      ],
    );
  }
}
