import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/graphql_client.dart';
import '../../services/share_out.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

/// The group's cycle number for display: the server stores 0 for a group
/// that has never closed a cycle and treats it as cycle 1.
int currentCycle(Map<String, dynamic>? group) {
  final c = (group?['cycleCurrent'] as num?)?.toInt() ?? 1;
  return c < 1 ? 1 : c;
}

/// End-of-cycle share-out (POST /api/main/share-out): one payment per
/// member, suggested as their own savings + shares plus a pro-rata share of
/// the profit, editable. Closing the cycle as well needs group.settings.
class CloseCycleScreen extends StatefulWidget {
  const CloseCycleScreen({super.key});

  @override
  State<CloseCycleScreen> createState() => _CloseCycleScreenState();
}

class _CloseCycleScreenState extends State<CloseCycleScreen> {
  ShareOutPlan? _plan;
  final Map<String, TextEditingController> _amounts = {};
  bool _closeCycle = false;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _amounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final state = AppState.I;
    await Future.wait([
      state.fetchTransactions(refresh: true),
      state.fetchMemberBalances(refresh: true),
      state.fetchLoans(refresh: true),
      state.fetchGovLoans(refresh: true),
    ]);
    if (!mounted) return;
    final txns = state.transactions;
    final plan = planShareOut(
      transactions: txns,
      govLoans: state.govLoans,
      // Active members, plus anyone else who still has money in the group.
      members: state.memberBalances
          .where((m) =>
              '${m['status'] ?? 'Active'}'.toLowerCase() == 'active' ||
              memberPool(txns, '${m['id']}').savings +
                      memberPool(txns, '${m['id']}').shares >
                  0)
          .toList(),
    );
    setState(() {
      _plan = plan;
      for (final l in plan.lines) {
        _amounts[l.memberId] = TextEditingController(
          text: l.suggested.toStringAsFixed(0),
        )..addListener(() => setState(() {}));
      }
      _loading = false;
    });
  }

  double _amountOf(String memberId) =>
      double.tryParse(
          (_amounts[memberId]?.text ?? '').replaceAll(',', '').trim()) ??
      0;

  double get _total =>
      _plan?.lines.fold<double>(0, (s, l) => s + _amountOf(l.memberId)) ?? 0;

  List<Map<String, dynamic>> get _payouts => [
        for (final l in _plan?.lines ?? const <ShareOutLine>[])
          if (_amountOf(l.memberId) > 0)
            {'memberId': l.memberId, 'amount': _amountOf(l.memberId)},
      ];

  Future<void> _submit() async {
    final plan = _plan;
    if (plan == null) return;
    final state = AppState.I;
    final payouts = _payouts;
    if (payouts.isEmpty) {
      setState(() => _error = tr('Enter at least one payout.'));
      return;
    }
    if (_total > plan.available + 0.005) {
      setState(() => _error = tr(
          'The share-out ({0}) is more than the cash available to share ({1}).',
          [state.money(_total), state.money(plan.available)]));
      return;
    }
    final cycle = currentCycle(state.group);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Confirm share-out')),
        content: Text([
          tr('Pay out {0} to {1} members?', [state.money(_total), payouts.length]),
          if (_closeCycle)
            tr('Cycle {0} will be closed and cycle {1} started.', [cycle, cycle + 1]),
          tr('Each payment is recorded as a transaction and can be reversed.'),
        ].join('\n\n')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Pay out'))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await state.shareOut(payouts: payouts, closeCycle: _closeCycle);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('Share-out recorded: {0} to {1} members', [
          state.money(_total),
          payouts.length,
        ])),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.meetingsList,
        (route) => route.isFirst,
      );
    } on GraphQLException catch (e) {
      if (mounted) setState(() => _error = e.message); // the server's reason
    } catch (_) {
      if (mounted) setState(() => _error = tr('Could not save. Try again.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final plan = _plan;
    final cycle = currentCycle(state.group);
    final canClose = state.can('group.settings');
    final over = plan != null && _total > plan.available + 0.005;

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
                title: tr('Share-out'),
                subtitle: tr('Cycle {0}', [cycle]),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 20),
              if (_loading || plan == null)
                const HxSkeletonList(rows: 6)
              else ...[
                HxSurface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      HxKV(label: 'Cash in the box', value: state.money(plan.cash)),
                      HxKV(
                        label: 'Social fund (kept apart)',
                        value: state.money(plan.socialFund),
                      ),
                      HxKV(
                        key: const ValueKey('shareout-available'),
                        label: 'Available to share',
                        value: state.money(plan.available),
                        bold: true,
                      ),
                      const Divider(height: 16),
                      HxKV(
                        label: "Members' savings + shares",
                        value: state.money(plan.poolTotal),
                      ),
                      HxKV(
                        key: const ValueKey('shareout-profit'),
                        label: 'Profit to share',
                        value: state.money(plan.profit),
                      ),
                    ],
                  ),
                ),
                if (state.groupLoansOut > 0) ...[
                  const SizedBox(height: 12),
                  HxHint(
                    icon: Icons.warning_amber_rounded,
                    background: AppColors.gold100,
                    foreground: AppColors.teal900,
                    text: tr('Loans still outstanding: {0}. Collect them first so that money is in the box to share.',
                        [state.money(state.groupLoansOut)]),
                  ),
                ],
                const SizedBox(height: 20),
                const HxSectionTitle(title: 'Payout per member'),
                const SizedBox(height: 4),
                Text(
                  tr('Suggested: own savings + shares plus a share of the profit in proportion. You can change any amount; 0 leaves a member out.'),
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400),
                ),
                const SizedBox(height: 12),
                if (plan.lines.isEmpty)
                  const HxEmpty(
                    icon: Icons.groups_outlined,
                    title: 'No members to pay',
                    message: 'Members with savings or shares appear here.',
                  )
                else
                  HxSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < plan.lines.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _PayoutRow(
                            line: plan.lines[i],
                            controller: _amounts[plan.lines[i].memberId]!,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                HxKV(
                  key: const ValueKey('shareout-total'),
                  label: 'Total to pay out',
                  value: state.money(_total),
                  bold: true,
                ),
                if (over)
                  Text(
                    tr('More than the cash available to share.'),
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.danger),
                  ),
                if (canClose) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    key: const ValueKey('shareout-close-cycle'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _closeCycle,
                    onChanged: (v) => setState(() => _closeCycle = v ?? false),
                    title: Text(
                      tr('Also close cycle {0} and start cycle {1}', [cycle, cycle + 1]),
                      style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.ink900),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    key: const ValueKey('shareout-error'),
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 20),
                HxButton(
                  text: tr('Pay out {0}', [state.money(_total)]),
                  loading: _submitting,
                  onPressed: _submitting || plan.lines.isEmpty ? null : _submit,
                ),
                const SizedBox(height: 12),
                HxButton(
                  text: tr('Cancel'),
                  variant: HxButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).maybePop(),
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

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({
    required this.line,
    required this.controller,
  });

  final ShareOutLine line;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name.isEmpty ? '—' : line.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr('Savings {0} · Shares {1}', [
                    state.money(line.savings),
                    state.money(line.shares),
                  ]),
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.ink400),
                ),
                if (line.exceeds(double.tryParse(
                        controller.text.replaceAll(',', '').trim()) ??
                    0)) ...[
                  const SizedBox(height: 2),
                  Text(
                    tr("More than this member's entitlement ({0})",
                        [state.money(line.entitlement.floorToDouble())]),
                    key: ValueKey('over-${line.memberId}'),
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: TextField(
              key: ValueKey('payout-${line.memberId}'),
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              decoration: const InputDecoration(isDense: true, prefixText: 'TZS '),
            ),
          ),
        ],
      ),
    );
  }
}
