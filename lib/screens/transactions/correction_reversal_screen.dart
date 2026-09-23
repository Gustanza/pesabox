import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/i18n.dart';
import '../../services/app_data.dart';
import '../../services/graphql_client.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

/// Fixes a mistake on a recorded transaction. Financial records are never
/// edited or deleted (TODO.md D5): the original is marked "reversed" — every
/// balance and report then ignores it — and whatever it changed (group totals,
/// a loan's or fine's paid amount) is put back. To fix a wrong amount, reverse
/// it and record the transaction again with the right figure. The reason is
/// kept in the audit log.
class CorrectionReversalScreen extends StatefulWidget {
  const CorrectionReversalScreen({super.key, this.transactionId = ''});

  final String transactionId;

  @override
  State<CorrectionReversalScreen> createState() =>
      _CorrectionReversalScreenState();
}

class _CorrectionReversalScreenState extends State<CorrectionReversalScreen> {
  final _reason = TextEditingController();
  Map<String, dynamic>? _txn;
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
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final txns = await AppState.I.fetchTransactions(refresh: true);
    if (!mounted) return;
    setState(() {
      for (final t in txns) {
        if (t['id'] == widget.transactionId) _txn = t;
      }
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) {
      setState(
        () => _error = tr('Explain why this transaction is being reversed'),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Reverse transaction')),
        content: Text(
          tr(
            'The original stays in the records, marked as reversed, and the balances are put back. This cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Reverse')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppState.I.reverseTransaction(
        widget.transactionId,
        _reason.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('Transaction reversed'))));
      Navigator.of(context).pop(true);
    } on GraphQLException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
        () => _error = tr('Could not reverse the transaction. Try again.'),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final txn = _txn;
    final canReverse = state.can('finance.write');
    final reversed = txn?['reversed'] == true;
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
                title: tr('Correction / Reversal'),
                subtitle: txn == null
                    ? ''
                    : state.txnTypeLabel('${txn['type']}'),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold100,
                  borderRadius: AppRadius.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.gold500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(
                          'Money records are never edited or deleted. Reversing keeps the original (marked reversed) and puts the balances back. To fix a wrong amount, reverse it, then record it again with the right amount.',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.teal900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (txn == null)
                Text(
                  tr('Transaction not found.'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.ink600,
                  ),
                )
              else ...[
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
                      _kv(tr('Type'), state.txnTypeLabel('${txn['type']}')),
                      _kv(tr('Amount'), state.money(txn['amount'] as num?)),
                      _kv(tr('Member'), '${txn['memberName'] ?? '—'}'),
                      _kv(tr('Date/Time'), state.isoDateTime(txn['createdAt'])),
                      if (reversed) _kv(tr('Status'), tr('Reversed')),
                      if (reversed &&
                          '${txn['reversalReason'] ?? ''}'.isNotEmpty)
                        _kv(tr('Reason'), '${txn['reversalReason']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (reversed)
                  Text(
                    tr('This transaction has already been reversed.'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink600,
                    ),
                  )
                else if (!canReverse)
                  Text(
                    tr(
                      'Your role in this group does not allow reversing transactions.',
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink600,
                    ),
                  )
                else ...[
                  AuthTextField(
                    label: tr('Reason'),
                    hint: tr('Explain why this transaction is being reversed'),
                    controller: _reason,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.ink400,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md,
                        ),
                      ),
                      child: Text(
                        _saving ? tr('Reversing…') : tr('Reverse transaction'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
        ),
      ],
    ),
  );
}
