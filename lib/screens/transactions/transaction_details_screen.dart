import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';
import '../../i18n/i18n.dart';

class TransactionDetailsScreen extends StatefulWidget {
  const TransactionDetailsScreen({super.key, this.transactionId = ''});

  final String transactionId;

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  Map<String, dynamic>? _txn;
  Map<String, dynamic>? _meeting;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = AppState.I;
    final txn = await state.transactionById(widget.transactionId);
    Map<String, dynamic>? meeting;
    final meetingId = txn?['meetingId']?.toString();
    if (meetingId != null && meetingId.isNotEmpty) {
      meeting = await state.meetingById(meetingId);
    }
    if (!mounted) return;
    setState(() {
      _txn = txn;
      _meeting = meeting;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final txn = _txn;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AuthHeader(title: tr('Transaction Details')),
              const SizedBox(height: 20),
              if (_loading)
                const HxSkeletonList(rows: 6)
              else if (txn == null)
                Text(
                  tr('Transaction not found.'),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
                )
              else ...[
                _buildAmountCard(state, txn),
                const SizedBox(height: 16),
                _buildDetailsCard(state, txn),
                const SizedBox(height: 24),
                if (txn['reversed'] != true && state.can('finance.write'))
                  OutlineButton(
                    text: tr('Correct / reverse transaction'),
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(
                        AppRouter.correctionReversalPath(widget.transactionId),
                      );
                      _load();
                    },
                  ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(AppState state, Map<String, dynamic> txn) {
    final reversed = txn['reversed'] == true;
    final type = txn['type']?.toString() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reversed ? AppColors.danger100 : AppColors.green100,
            ),
            child: Icon(
              reversed ? Icons.undo_rounded : Icons.check_rounded,
              size: 32,
              color: reversed ? AppColors.danger : AppColors.green600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            state.money((txn['amount'] as num?) ?? 0),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            txn['description']?.toString().isNotEmpty == true
                ? txn['description'].toString()
                : state.txnTypeLabel(type),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.ink400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(AppState state, Map<String, dynamic> txn) {
    final member = (txn['fullName'] as String?)?.isNotEmpty == true
        ? txn['fullName'] as String
        : (txn['memberName']?.toString() ?? txn['memberPhone']?.toString() ?? '—');
    final meeting = _meeting;
    final meetingLabel = meeting == null
        ? '—'
        : (meeting['title']?.toString().isNotEmpty == true
            ? meeting['title'].toString()
            : tr('Meeting #{0}', [meeting['meetingNumber'] ?? '']));
    final reference = txn['reference']?.toString() ?? '';
    final reversed = txn['reversed'] == true;

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
          _KVRow(label: 'Transaction ID', value: txn['id']?.toString() ?? '—'),
          const Divider(height: 24),
          _KVRow(label: 'Member', value: member),
          const Divider(height: 24),
          _KVRow(label: 'Meeting', value: meetingLabel),
          const Divider(height: 24),
          _KVRow(
            label: 'Type',
            value: state.txnTypeLabel(txn['type']?.toString() ?? ''),
          ),
          const Divider(height: 24),
          _KVRow(
            label: 'Payment method',
            value: txn['method']?.toString().isNotEmpty == true
                ? txn['method'].toString()
                : tr('Cash'),
          ),
          if (reference.isNotEmpty) ...[
            const Divider(height: 24),
            _KVRow(label: 'Reference', value: reference),
          ],
          const Divider(height: 24),
          _KVRow(
            label: 'Date/Time',
            value: state.isoDateTime(txn['createdAt']),
          ),
          const Divider(height: 24),
          _StatusRow(reversed: reversed),
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
        Text(
          tr(label),
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool reversed;
  const _StatusRow({required this.reversed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr('Status'),
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: reversed ? AppColors.danger100 : AppColors.green100,
            borderRadius: AppRadius.sm,
          ),
          child: Text(
            reversed ? tr('Reversed') : tr('Completed'),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: reversed ? AppColors.danger : AppColors.teal800,
            ),
          ),
        ),
      ],
    );
  }
}
