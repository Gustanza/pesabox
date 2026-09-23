import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/i18n.dart';
import '../../services/app_data.dart';
import '../../services/graphql_client.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

/// Government / outside loans TO THE GROUP (e.g. council 10% loans for women,
/// youth and people with disabilities, a bank or an NGO) — TODO.md §7. Kept
/// separate from members' savings so the group's own balances stay honest; if
/// the group lends the money on to members, those are recorded as ordinary
/// member loans.
class GovLoansScreen extends StatefulWidget {
  const GovLoansScreen({super.key});

  @override
  State<GovLoansScreen> createState() => _GovLoansScreenState();
}

class _GovLoansScreenState extends State<GovLoansScreen> {
  bool _loading = true;

  bool get _canRecord => AppState.I.can('finance.write');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AppState.I.fetchGovLoans(refresh: true);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openSheet(Widget sheet) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheet,
    );
    if (done == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final loans = state.govLoans;
    final received = loans.fold<double>(
      0,
      (s, l) => s + ((l['amount'] as num?)?.toDouble() ?? 0),
    );
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                AuthHeader(
                  title: tr('Government loans'),
                  subtitle: tr('Loans the group received from outside'),
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: tr('Received'),
                        value: state.money(received),
                        color: AppColors.teal800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(
                        label: tr('Still owed'),
                        value: state.money(state.govLoansOutstanding),
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tr(
                    "Kept separate from members' savings. If the group lends this money to members, record those as normal member loans.",
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.ink400,
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (loans.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.md,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      tr('No government loans recorded.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink400,
                      ),
                    ),
                  )
                else
                  for (final l in loans) ...[
                    _LoanCard(
                      loan: l,
                      onRepay: _canRecord && l['status'] != 'repaid'
                          ? () => _openSheet(_RepaySheet(loan: l))
                          : null,
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 14),
                if (_canRecord)
                  PrimaryButton(
                    text: tr('Record government loan'),
                    onPressed: () => _openSheet(const _RecordSheet()),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.ink400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final VoidCallback? onRepay;

  const _LoanCard({required this.loan, this.onRepay});

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final overdue = loan['overdue'] == true;
    final status = '${loan['status'] ?? 'active'}';
    final statusText = overdue
        ? tr('Overdue')
        : status == 'repaid'
        ? tr('Repaid')
        : status == 'defaulted'
        ? tr('Defaulted')
        : tr('Active');
    final statusColor = overdue || status == 'defaulted'
        ? AppColors.danger
        : status == 'repaid'
        ? AppColors.green600
        : AppColors.gold500;
    final sub = [
      loan['programme'],
      loan['reference'],
    ].where((x) => x != null && '$x'.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${loan['lender'] ?? ''}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink400),
            ),
          ],
          const SizedBox(height: 10),
          _kv(tr('Amount'), state.money(loan['amount'] as num?)),
          _kv(tr('Interest'), '${loan['interestRate'] ?? 0}%'),
          _kv(tr('Repaid'), state.money(loan['amountRepaid'] as num?)),
          _kv(
            tr('Balance'),
            state.money(loan['outstanding'] as num?),
            strong: true,
          ),
          _kv(
            tr('Due date'),
            loan['dueDate'] == null ? '—' : state.isoDate(loan['dueDate']),
          ),
          if (onRepay != null) ...[
            const SizedBox(height: 10),
            OutlineButton(text: tr('Record repayment'), onPressed: onRepay),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          k,
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.ink600),
        ),
        Text(
          v,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.ink900,
          ),
        ),
      ],
    ),
  );
}

class _RecordSheet extends StatefulWidget {
  const _RecordSheet();

  @override
  State<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends State<_RecordSheet> {
  final _lender = TextEditingController();
  final _programme = TextEditingController();
  final _reference = TextEditingController();
  final _amount = TextEditingController();
  final _interest = TextEditingController(text: '0');
  final _term = TextEditingController(text: '12');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _lender,
      _programme,
      _reference,
      _amount,
      _interest,
      _term,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(_amount.text.replaceAll(',', '').trim()) ?? 0;
    if (_lender.text.trim().isEmpty || amount <= 0) {
      setState(() => _error = tr('Enter the lender and a positive amount'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppState.I.recordGovLoan(
        lender: _lender.text.trim(),
        programme: _programme.text.trim(),
        reference: _reference.text.trim(),
        amount: amount,
        interestRate: double.tryParse(_interest.text.trim()) ?? 0,
        termMonths: int.tryParse(_term.text.trim()) ?? 0,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on GraphQLException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = tr('Could not save. Try again.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Record government loan'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: tr('Lender'),
              hint: tr('e.g. Halmashauri ya Arusha'),
              controller: _lender,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              label: tr('Programme'),
              hint: tr('e.g. 10% women loan'),
              requiredField: false,
              controller: _programme,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              label: tr('Amount (TZS)'),
              hint: '1,000,000',
              keyboardType: TextInputType.number,
              controller: _amount,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AuthTextField(
                    label: tr('Interest %'),
                    hint: '0',
                    requiredField: false,
                    keyboardType: TextInputType.number,
                    controller: _interest,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AuthTextField(
                    label: tr('Term (months)'),
                    hint: '12',
                    requiredField: false,
                    keyboardType: TextInputType.number,
                    controller: _term,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AuthTextField(
              label: tr('Agreement / reference no.'),
              hint: '',
              requiredField: false,
              controller: _reference,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.danger,
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              text: _saving ? tr('Saving…') : tr('Save'),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _RepaySheet extends StatefulWidget {
  final Map<String, dynamic> loan;

  const _RepaySheet({required this.loan});

  @override
  State<_RepaySheet> createState() => _RepaySheetState();
}

class _RepaySheetState extends State<_RepaySheet> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  String _method = 'Cash';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(_amount.text.replaceAll(',', '').trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _error = tr('Enter a positive amount'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppState.I.repayGovLoan(
        '${widget.loan['id']}',
        amount,
        method: _method,
        reference: _reference.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on GraphQLException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = tr('Could not save. Try again.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Record repayment'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('{0} · balance {1}', [
                '${widget.loan['lender']}',
                AppState.I.money(widget.loan['outstanding'] as num?),
              ]),
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.ink400),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: tr('Amount (TZS)'),
              hint: '100,000',
              keyboardType: TextInputType.number,
              controller: _amount,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final m in ['Cash', 'Mobile Money', 'Bank Transfer'])
                  ChoiceChip(
                    label: Text(tr(m)),
                    selected: _method == m,
                    onSelected: (_) => setState(() => _method = m),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AuthTextField(
              label: tr('Reference'),
              hint: '',
              requiredField: false,
              controller: _reference,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.danger,
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              text: _saving ? tr('Saving…') : tr('Save'),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
