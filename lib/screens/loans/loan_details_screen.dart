import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/report_data.dart';
import '../../services/route_observer.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

class LoanDetailsScreen extends StatefulWidget {
  const LoanDetailsScreen({super.key, this.loanId = 'l3'});

  final String loanId;

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen>
    with AutoRefreshOnPop {
  Map<String, dynamic>? _loan;
  Map<String, dynamic>? _member;
  String? _meetingId;
  bool _loading = true;

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
    final state = AppState.I;
    // loanById only refetches the whole list when nothing's cached yet, so
    // force a refresh first — otherwise a repayment recorded on this exact
    // loan (which _restPost patches into the cache locally already) is
    // fine, but any other change made elsewhere (a correction/reversal from
    // another screen) wouldn't be picked up.
    await state.fetchLoans(refresh: true);
    final loan = await state.loanById(widget.loanId);
    final member = await state.memberById(loan?['memberId']?.toString());
    if (!mounted) return;
    setState(() {
      _loan = loan;
      _member = member;
      _loading = false;
    });
  }

  String get _memberName {
    final m = _member;
    if (m == null) return tr('Unknown member');
    final name = [m['firstName'], m['lastName']]
        .where((s) => (s ?? '').toString().isNotEmpty)
        .join(' ');
    return name.isEmpty ? tr('Unknown member') : name;
  }

  String get _initials {
    final parts = _memberName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return ('$first$last').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final loan = _loan;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Loan Details'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink900),
                        ),
                        Text(
                          tr(_loading ? '' : _memberName),
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const HxSkeletonList(rows: 6)
              else if (loan == null)
                Text(tr('Loan not found.'), style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600))
              else ...[
                _AvatarCard(
                  name: _memberName,
                  initials: _initials,
                  loanNumber: loan['loanNumber']?.toString() ?? '—',
                  active: loan['status'] == 'active',
                ),
                const SizedBox(height: 16),
                _KeyValueCard(loan: loan, state: state),
                const SizedBox(height: 24),
                HxButton(
                  text: loan['status'] == 'active'
                      ? tr('Record repayment')
                      : tr('Loan repaid'),
                  onPressed: loan['status'] == 'active'
                      ? () {
                          Navigator.of(context).pushNamed(
                            AppRouter.loanRepaymentPath(widget.loanId),
                            arguments: _meetingId,
                          );
                        }
                      : null,
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

class _AvatarCard extends StatelessWidget {
  final String name;
  final String initials;
  final String loanNumber;
  final bool active;

  const _AvatarCard({
    required this.name,
    required this.initials,
    required this.loanNumber,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.green600, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(tr(initials), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(name), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                const SizedBox(height: 2),
                Text(tr('Loan #{0}', [loanNumber]), style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400)),
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
        ],
      ),
    );
  }
}

class _KeyValueCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final AppState state;

  const _KeyValueCard({required this.loan, required this.state});

  @override
  Widget build(BuildContext context) {
    final amount = (loan['amount'] as num?)?.toDouble() ?? 0;
    final repaid = (loan['amountRepaid'] as num?)?.toDouble() ?? 0;
    // Terms fixed at issue: principal + flat interest (older loans: principal only).
    final interest = loanInterest(loan);
    final totalDue = loanTotalDue(loan);
    final outstanding = loanBalance(loan);
    final active = loan['status'] == 'active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _KVRow(label: tr('Principal'), value: state.money(amount)),
          const Divider(height: 24),
          _KVRow(
            label: tr('Interest'),
            value: loan['status'] == 'cancelled'
                ? '—'
                : loan['totalDue'] == null
                ? tr('None (issued before interest was charged)')
                : '${state.money(interest)} (${(loan['interestRate'] as num?)?.toStringAsFixed(0) ?? '0'}%)',
          ),
          const Divider(height: 24),
          _KVRow(label: tr('Total to repay'), value: loan['status'] == 'cancelled' ? '—' : state.money(totalDue)),
          const Divider(height: 24),
          _KVRow(label: tr('Duration'), value: '${state.maxLoanPeriodMonths} months'),
          const Divider(height: 24),
          _KVRow(
            label: tr('Disbursed'),
            value: state.shortDate(loan['issuedDate']?.toString().split('T').first),
          ),
          const Divider(height: 24),
          _KVRow(label: tr('Amount repaid'), value: state.money(repaid)),
          const Divider(height: 24),
          _KVRow(label: tr('Outstanding'), value: state.money(outstanding)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('Status'), style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.green100 : AppColors.line,
                  borderRadius: AppRadius.sm,
                ),
                child: Text(
                  active ? tr('Active') : tr('Repaid'),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: active ? AppColors.teal800 : AppColors.ink600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;

  const _KVRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(tr(label), style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600)),
        Text(tr(value), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink900)),
      ],
    );
  }
}
