import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';

class FinesListScreen extends StatefulWidget {
  const FinesListScreen({super.key});

  @override
  State<FinesListScreen> createState() => _FinesListScreenState();
}

class _FinesListScreenState extends State<FinesListScreen>
    with AutoRefreshOnPop {
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

  @override
  void onReturnedToScreen() => _load();

  Future<void> _load() async {
    final list = await AppState.I.fetchFines(refresh: true);
    if (mounted) {
      setState(() {
        _fines = list;
        _loading = false;
      });
    }
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

  Future<void> _pay(Map<String, dynamic> fine) async {
    final amount = (fine['amount'] as num?)?.toDouble() ?? 0;
    final paid = (fine['amountPaid'] as num?)?.toDouble() ?? 0;
    final remaining = amount - paid;
    final controller =
        TextEditingController(text: remaining.toStringAsFixed(0));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tr('Pay fine'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('{0} remaining', [AppState.I.money(remaining)]),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
            ),
            const SizedBox(height: AppSpace.x12),
            HxField(
              label: tr('Amount paid'),
              controller: controller,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Pay')),
          ),
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
      (sum, f) =>
          sum + (((f['amount'] as num? ?? 0) - (f['amountPaid'] as num? ?? 0))),
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x16),
              HxHeader(
                title: tr('Fines'),
                actions: [
                  HxIconButton(
                    icon: Icons.add_rounded,
                    tooltip: tr('Record fine'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.recordFine,
                        arguments: _meetingId,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.x16),
              if (_loading)
                const _LoadingSkeleton()
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: HxStat(
                        label: tr('Total fines'),
                        value: state.money(total),
                        valueColor: AppColors.teal800,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: tr('Unpaid'),
                        value: state.money(unpaid),
                        valueColor: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x24),
                const HxSectionTitle(title: 'Recent fines'),
                const SizedBox(height: AppSpace.x12),
                if (_fines.isEmpty)
                  HxEmpty(
                    icon: Icons.gavel_outlined,
                    title: 'No fines yet',
                    message: 'Issue a fine to keep the group rules enforced.',
                  )
                else
                  HxSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < _fines.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 64),
                          HxRow(
                            onTap: _fines[i]['status'] == 'paid'
                                ? null
                                : () => _pay(_fines[i]),
                            leading: HxAvatar(
                              initials: state.initials(
                                  _memberName(_fines[i]['memberId']?.toString())),
                            ),
                            title: _memberName(_fines[i]['memberId']?.toString()),
                            subtitle: '${_fines[i]['reason']?.toString() ?? ''} · '
                                '${state.money((_fines[i]['amount'] as num?) ?? 0)}',
                            trailing: _statusPill(
                                _fines[i]['status']?.toString() ?? 'pending'),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpace.x24),
                if (!_loading)
                  HxButton(
                    text: tr('Record a fine'),
                    icon: Icons.gavel_rounded,
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.recordFine,
                        arguments: _meetingId,
                      );
                    },
                  ),
              ],
              const SizedBox(height: AppSpace.x32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    switch (status) {
      case 'paid':
        return HxPill(text: 'Paid', tone: HxPillTone.success);
      case 'waived':
        return HxPill(text: tr('Waived'), tone: HxPillTone.neutral);
      default:
        return HxPill(text: 'Unpaid', tone: HxPillTone.danger);
    }
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HxSkeletonStats(),
        SizedBox(height: AppSpace.x20),
        HxSkeleton(width: 130, height: 14),
        SizedBox(height: AppSpace.x12),
        HxSkeletonList(rows: 4),
      ],
    );
  }
}