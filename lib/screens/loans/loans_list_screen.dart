import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';

class LoansListScreen extends StatefulWidget {
  const LoansListScreen({super.key});

  @override
  State<LoansListScreen> createState() => _LoansListScreenState();
}

class _LoansListScreenState extends State<LoansListScreen>
    with AutoRefreshOnPop {
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

  @override
  void onReturnedToScreen() => _load();

  Future<void> _load() async {
    final list = await AppState.I.fetchLoans(refresh: true);
    if (mounted) {
      setState(() {
        _loans = list;
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x16),
              HxHeader(
                title: tr('Loans'),
                actions: [
                  HxIconButton(
                    icon: Icons.add_rounded,
                    tooltip: tr('Record loan'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.recordLoan,
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
                        label: tr('Active loans'),
                        value: '${active.length}',
                        valueColor: AppColors.teal800,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: tr('Outstanding'),
                        value: state.money(outstanding),
                        valueColor: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x12),
                Row(
                  children: [
                    Expanded(
                      child: HxStat(
                        label: tr('Total loaned'),
                        value: state.money(totalLoaned),
                        valueColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: HxStat(
                        label: tr('Total repaid'),
                        value: state.money(totalRepaid),
                        valueColor: AppColors.teal800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x24),
                const HxSectionTitle(title: 'Recent loans'),
                const SizedBox(height: AppSpace.x12),
                if (_loans.isEmpty)
                  HxEmpty(
                    icon: Icons.request_quote_outlined,
                    title: 'No loans yet',
                    message: 'Record the first loan from a meeting.',
                  )
                else
                  HxSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < _loans.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 64),
                          _LoanRow(
                            name: _memberName(_loans[i]['memberId']?.toString()),
                            loan: _loans[i],
                            state: state,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.loanDetailsPath(
                                    _loans[i]['id']?.toString() ?? ''),
                                arguments: _meetingId,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: AppSpace.x24),
            ],
          ),
        ),
      ),
    );
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
        SizedBox(height: AppSpace.x12),
        HxSkeletonStats(),
        SizedBox(height: AppSpace.x20),
        HxSkeleton(width: 130, height: 14),
        SizedBox(height: AppSpace.x12),
        HxSkeletonList(rows: 4),
      ],
    );
  }
}

class _LoanRow extends StatelessWidget {
  final String name;
  final Map<String, dynamic> loan;
  final AppState state;
  final VoidCallback onTap;

  const _LoanRow({
    required this.name,
    required this.loan,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = loan['status']?.toString() ?? 'active';
    final active = status == 'active';
    return HxRow(
      onTap: onTap,
      leading: HxAvatar(initials: state.initials(name)),
      title: name,
      subtitle:
          '${state.money((loan['amount'] as num?) ?? 0)} · ${state.maxLoanPeriodMonths} months',
      trailing: HxPill(
        text: active ? tr('Active') : tr('Repaid'),
        tone: active ? HxPillTone.success : HxPillTone.neutral,
      ),
    );
  }
}