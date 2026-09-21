import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/i18n.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

/// Pick the datasets you need (and optionally their columns), a date range and
/// a format, then export them as one PDF / Excel / CSV file.
class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key, this.service});

  /// Injectable for tests; the app uses the real server.
  final ReportService? service;

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  late final ReportService _service = widget.service ?? LocalReportService();

  List<ReportDataset> _datasets = [];
  final Set<String> _selected = {};
  final Map<String, Set<String>> _columns = {}; // dataset -> chosen column keys
  final Set<String> _expanded = {};
  String _format = 'xlsx';
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
      final list = await _service.datasets();
      if (!mounted) return;
      setState(() {
        _datasets = list;
        for (final d in list) {
          _columns[d.key] = {for (final c in d.columns) c.key};
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst('Exception: ', '');
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
  }

  Future<void> _export() async {
    if (_selected.isEmpty || _exporting) return;

    // Only send a column list for datasets where something was unticked.
    final columns = <String, List<String>>{};
    for (final d in _datasets.where((d) => _selected.contains(d.key))) {
      final keep = d.columns.where((c) => _columns[d.key]!.contains(c.key));
      if (keep.isEmpty) {
        setState(() => _error = tr('Choose at least one column for {0}', [d.label]));
        return;
      }
      if (keep.length != d.columns.length) {
        columns[d.key] = [for (final c in keep) c.key];
      }
    }

    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final file = await _service.export(
        datasets: [
          for (final d in _datasets)
            if (_selected.contains(d.key)) d.key,
        ],
        columns: columns,
        format: _format,
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
      setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _selected.length;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AuthHeader(title: tr('Export reports')),
            ),
            Expanded(child: _body()),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: PrimaryButton(
                text: _exporting
                    ? tr('Preparing…')
                    : tr('Export {0} dataset(s)', [n]),
                onPressed: (n == 0 || _exporting) ? null : _export,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.teal900));
    }
    if (_datasets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? tr('Could not load the report list'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.danger),
              ),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: _load, child: Text(tr('Try again'))),
            ],
          ),
        ),
      );
    }

    final categories = <String, List<ReportDataset>>{};
    for (final d in _datasets) {
      categories.putIfAbsent(d.categoryLabel, () => []).add(d);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text(
          tr('Choose the data you need, then export it as PDF, Excel or CSV.'),
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600, height: 1.5),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _selected.addAll(_datasets.map((d) => d.key))),
              child: Text(tr('Select all')),
            ),
            TextButton(
              onPressed: () => setState(_selected.clear),
              child: Text(tr('None')),
            ),
          ],
        ),
        for (final entry in categories.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              entry.key,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < entry.value.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _datasetTile(entry.value[i]),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          tr('Date range'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _dateButton(tr('From'), _from, () => _pickDate(from: true), () => setState(() => _from = null))),
            const SizedBox(width: 10),
            Expanded(child: _dateButton(tr('To'), _to, () => _pickDate(from: false), () => setState(() => _to = null))),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          tr('Format'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            for (final f in const [('pdf', 'PDF'), ('xlsx', 'Excel'), ('csv', 'CSV')])
              ChoiceChip(
                label: Text(f.$2),
                selected: _format == f.$1,
                selectedColor: AppColors.green600,
                labelStyle: TextStyle(
                  color: _format == f.$1 ? AppColors.white : AppColors.ink900,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _format = f.$1),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          tr('Excel gives one sheet per dataset, PDF one section per dataset. CSV with several datasets is a .zip.'),
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400, height: 1.5),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(
            _error!,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap, VoidCallback onClear) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  Widget _datasetTile(ReportDataset d) {
    final open = _expanded.contains(d.key);
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() {
            _selected.contains(d.key) ? _selected.remove(d.key) : _selected.add(d.key);
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: _selected.contains(d.key),
                  activeColor: AppColors.green600,
                  onChanged: (v) => setState(() {
                    v == true ? _selected.add(d.key) : _selected.remove(d.key);
                  }),
                ),
                Expanded(
                  child: Text(
                    d.label,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink900),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    open ? _expanded.remove(d.key) : _expanded.add(d.key);
                  }),
                  child: Text(open ? tr('Hide columns') : tr('Columns')),
                ),
              ],
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                for (final c in d.columns)
                  FilterChip(
                    label: Text(c.label, style: const TextStyle(fontSize: 12)),
                    selected: _columns[d.key]!.contains(c.key),
                    selectedColor: AppColors.green100,
                    checkmarkColor: AppColors.green600,
                    onSelected: (v) => setState(() {
                      v ? _columns[d.key]!.add(c.key) : _columns[d.key]!.remove(c.key);
                    }),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
