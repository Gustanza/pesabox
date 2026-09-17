import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class LoanDetailsScreen extends StatefulWidget {
  const LoanDetailsScreen({super.key, this.loanId = 'l3'});

  final String loanId;

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
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

  Future<void> _load() async {
    final state = AppState.I;
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
    if (m == null) return 'Unknown member';
    final name = [m['firstName'], m['lastName']]
        .where((s) => (s ?? '').toString().isNotEmpty)
        .join(' ');
    return name.isEmpty ? 'Unknown member' : name;
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
                          'Loan Details',
                          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink900),
                        ),
                        Text(
                          _loading ? '' : _memberName,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (loan == null)
                Text('Loan not found.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600))
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
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loan['status'] == 'active'
                        ? () async {
                            await Navigator.of(context).pushNamed(
                              AppRouter.loanRepaymentPath(widget.loanId),
                              arguments: _meetingId,
                            );
                            _load();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green600,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                    ),
                    child: Text(
                      loan['status'] == 'active' ? 'Record repayment' : 'Loan repaid',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white),
                    ),
                  ),
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
            child: Text(initials, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink900)),
                const SizedBox(height: 2),
                Text('Loan #$loanNumber', style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400)),
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
              active ? 'Active' : 'Repaid',
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
    final outstanding = amount - repaid;
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
          _KVRow(label: 'Principal', value: state.money(amount)),
          const Divider(height: 24),
          _KVRow(label: 'Interest', value: '${(loan['interestRate'] as num?)?.toStringAsFixed(0) ?? '0'}%'),
          const Divider(height: 24),
          _KVRow(label: 'Duration', value: '${state.maxLoanPeriodMonths} months'),
          const Divider(height: 24),
          _KVRow(
            label: 'Disbursed',
            value: state.shortDate(loan['issuedDate']?.toString().split('T').first),
          ),
          const Divider(height: 24),
          _KVRow(label: 'Amount repaid', value: state.money(repaid)),
          const Divider(height: 24),
          _KVRow(label: 'Outstanding', value: state.money(outstanding)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status', style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.green100 : AppColors.line,
                  borderRadius: AppRadius.sm,
                ),
                child: Text(
                  active ? 'Active' : 'Repaid',
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
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink900)),
      ],
    );
  }
}
