import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/i18n.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

/// Edits the group's rules (constitution) through the server's checked
/// route (`/api/main/group/rules`, server/group_rules.go). Only shown to the
/// Mwenyekiti (`group.settings`); the server re-checks and validates, and its
/// message is shown as-is. Changes apply to new records only.
class RulesEditScreen extends StatefulWidget {
  const RulesEditScreen({super.key, this.load, this.save});

  /// Injectable for tests; the app uses [AppState.fetchGroupRules] /
  /// [AppState.saveGroupRules].
  final Future<Map<String, dynamic>> Function()? load;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> rules)? save;

  @override
  State<RulesEditScreen> createState() => _RulesEditScreenState();
}

/// The numeric rules, in form order: (key, label, whole number).
const kRuleFields = <(String, String, bool)>[
  ('mandatorySavingsAmount', 'Mandatory savings per meeting (TZS)', false),
  ('shareValue', 'Share value (TZS)', false),
  ('minShares', 'Minimum shares per meeting', true),
  ('maxShares', 'Maximum shares per meeting', true),
  ('socialFundContribution', 'Social Fund per meeting (TZS)', false),
  ('loanInterestRate', 'Loan interest (% flat)', false),
  ('maxLoanPeriodMonths', 'Repayment period (months)', true),
  ('maxLoanMultiplier', 'Max loan (× savings + shares, 0 = no limit)', false),
];

class _Reason {
  _Reason(String reason, num amount)
      : reason = TextEditingController(text: reason),
        amount = TextEditingController(text: _fmt(amount));
  final TextEditingController reason;
  final TextEditingController amount;
}

String _fmt(Object? v) {
  if (v is num) return v == v.roundToDouble() ? v.toInt().toString() : '$v';
  return v == null ? '' : '$v';
}

class _RulesEditScreenState extends State<RulesEditScreen> {
  final Map<String, TextEditingController> _fields = {
    for (final f in kRuleFields) f.$1: TextEditingController(),
  };
  final List<_Reason> _reasons = [];
  final Set<String> _services = {};
  List<String> _allServices = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    for (final r in _reasons) {
      r.reason.dispose();
      r.amount.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await (widget.load ?? AppState.I.fetchGroupRules)();
      final rules = Map<String, dynamic>.from((data['rules'] as Map?) ?? const {});
      if (!mounted) return;
      setState(() {
        for (final f in kRuleFields) {
          _fields[f.$1]!.text = _fmt(rules[f.$1]);
        }
        _reasons
          ..clear()
          ..addAll([
            for (final r in (rules['fineReasons'] as List? ?? const []))
              if (r is Map) _Reason('${r['reason'] ?? ''}', (r['amount'] as num?) ?? 0),
          ]);
        _services
          ..clear()
          ..addAll([for (final s in (rules['enabledServices'] as List? ?? const [])) '$s']);
        _allServices = [for (final s in (data['services'] as List? ?? const [])) '$s'];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  /// A number when the text is one; otherwise the text itself, so the server
  /// names the rule that is wrong.
  Object? _value(String text) {
    final t = text.trim().replaceAll(',', '');
    if (t.isEmpty) return null;
    return num.tryParse(t) ?? t;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final rules = <String, dynamic>{
      for (final f in kRuleFields) f.$1: _value(_fields[f.$1]!.text),
      'fineReasons': [
        for (final r in _reasons) {'reason': r.reason.text.trim(), 'amount': _value(r.amount.text) ?? 0},
      ],
      'enabledServices': [for (final s in _allServices) if (_services.contains(s)) s],
    };
    try {
      await (widget.save ?? AppState.I.saveGroupRules)(rules);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Rules saved')), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).maybePop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpace.x16),
            HxHeader(
              title: tr('Edit group rules'),
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpace.x20),
                      child: HxSkeletonList(rows: 8),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpace.x20, 8, AppSpace.x20, AppSpace.x24),
                      children: [
                        HxHint(
                          text: tr('Changes apply to new records only. Existing loans keep the interest and total they were issued with.'),
                          icon: Icons.info_outline_rounded,
                        ),
                        const SizedBox(height: AppSpace.x16),
                        for (final f in kRuleFields) ...[
                          TextField(
                            key: ValueKey('rule-${f.$1}'),
                            controller: _fields[f.$1],
                            keyboardType: TextInputType.numberWithOptions(decimal: !f.$3),
                            decoration: _dec(tr(f.$2)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 8),
                        Text(tr('Fine reasons'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                        const SizedBox(height: 8),
                        for (var i = 0; i < _reasons.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    key: ValueKey('reason-$i'),
                                    controller: _reasons[i].reason,
                                    decoration: _dec(tr('Reason')),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    key: ValueKey('reason-amount-$i'),
                                    controller: _reasons[i].amount,
                                    keyboardType: TextInputType.number,
                                    decoration: _dec(tr('Amount')),
                                  ),
                                ),
                                IconButton(
                                  tooltip: tr('Remove'),
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                  onPressed: () => setState(() => _reasons.removeAt(i)),
                                ),
                              ],
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _reasons.add(_Reason('', 0))),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(tr('Add fine reason')),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(tr('Services the group uses'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                        for (final s in _allServices)
                          SwitchListTile(
                            key: ValueKey('service-$s'),
                            contentPadding: EdgeInsets.zero,
                            title: Text(tr(s)),
                            value: _services.contains(s),
                            activeTrackColor: AppColors.green600,
                            onChanged: (on) => setState(() => on ? _services.add(s) : _services.remove(s)),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger)),
                        ],
                        const SizedBox(height: 16),
                        HxButton(
                          text: tr('Save rules'),
                          loading: _saving,
                          onPressed: _saving ? null : _save,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
