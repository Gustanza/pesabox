import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class MemberStatementScreen extends StatelessWidget {
  const MemberStatementScreen({super.key, this.memberId = 'm1'});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final member = groupMembers.firstWhere(
      (m) => m.id == memberId,
      orElse: () => groupMembers.first,
    );

    final memberFines = fines.where((f) => f.memberId == memberId);
    final finesCharged = memberFines.fold(0.0, (sum, f) => sum + f.amount);
    final finesPaid = memberFines.fold(0.0, (sum, f) => sum + f.amountPaid);
    final finesOutstanding = finesCharged - finesPaid;

    final loansTaken = loans.where((l) => l.memberId == memberId).fold(
          0.0,
          (sum, l) => sum + l.amount,
        );

    final memberTransactions = transactions
        .where((t) => t.memberId == memberId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalShareValue = member.shareCount * shareValue;

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
                title: 'Member Statement',
                subtitle: member.fullName,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 20),
              _StatementSummaryCard(
                member: member,
                totalShareValue: totalShareValue,
                loansTaken: loansTaken,
                loanBalance: member.outstandingLoan,
                finesOutstanding: finesOutstanding,
              ),
              const SizedBox(height: 20),
              Text(
                'Transaction history',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 12),
              if (memberTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    'No transactions yet.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...memberTransactions.map(
                  (tx) => _StatementTransactionRow(transaction: tx),
                ),
              const SizedBox(height: 20),
              OutlineButton(
                text: 'Share statement',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Statement shared via SMS'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatementSummaryCard extends StatelessWidget {
  final Member member;
  final double totalShareValue;
  final double loansTaken;
  final double loanBalance;
  final double finesOutstanding;

  const _StatementSummaryCard({
    required this.member,
    required this.totalShareValue,
    required this.loansTaken,
    required this.loanBalance,
    required this.finesOutstanding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KVRow(
            label: 'Member since',
            value: _formatDate(member.joinedAt),
          ),
          _KVRow(
            label: 'Total savings',
            value: 'TZS ${_formatNum(member.savingsBalance)}',
          ),
          _KVRow(
            label: 'Total shares',
            value: 'TZS ${_formatNum(totalShareValue)}',
          ),
          _KVRow(
            label: 'Social Fund',
            value: 'TZS ${_formatNum(member.socialFundBalance)}',
          ),
          _KVRow(
            label: 'Loans taken',
            value: 'TZS ${_formatNum(loansTaken)}',
          ),
          _KVRow(
            label: 'Loan balance',
            value: 'TZS ${_formatNum(loanBalance)}',
            valueColor: loanBalance > 0 ? AppColors.danger : AppColors.ink900,
          ),
          _KVRow(
            label: 'Fines',
            value: finesOutstanding > 0
                ? 'TZS ${_formatNum(finesOutstanding)}'
                : 'TZS 0',
            valueColor:
                finesOutstanding > 0 ? AppColors.danger : AppColors.ink900,
          ),
        ],
      ),
    );
  }

  static String _formatNum(double amount) {
    return amount
        .toInt()
        .toString()
        .replaceAll(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), ',');
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _KVRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.ink600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementTransactionRow extends StatelessWidget {
  final Transaction transaction;
  const _StatementTransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, size: 18, color: _typeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.date),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.ink400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'TZS ${transaction.amount.toInt().toString().replaceAll(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), ',')}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }

  Color get _typeColor {
    switch (transaction.type) {
      case TransactionType.contribution:
        return AppColors.green600;
      case TransactionType.loanDisbursement:
        return AppColors.blue;
      case TransactionType.loanRepayment:
        return AppColors.teal700;
      case TransactionType.fine:
        return AppColors.danger;
      case TransactionType.socialFund:
        return AppColors.gold500;
      default:
        return AppColors.ink400;
    }
  }

  IconData get _typeIcon {
    switch (transaction.type) {
      case TransactionType.contribution:
        return Icons.savings_outlined;
      case TransactionType.loanDisbursement:
        return Icons.account_balance_outlined;
      case TransactionType.loanRepayment:
        return Icons.replay_outlined;
      case TransactionType.fine:
        return Icons.gavel_outlined;
      case TransactionType.socialFund:
        return Icons.people_outline;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String get _typeName {
    switch (transaction.type) {
      case TransactionType.contribution:
        return 'Contribution';
      case TransactionType.loanDisbursement:
        return 'Loan Disbursement';
      case TransactionType.loanRepayment:
        return 'Loan Repayment';
      case TransactionType.fine:
        return 'Fine';
      case TransactionType.socialFund:
        return 'Social Fund';
      case TransactionType.expense:
        return 'Expense';
      default:
        return 'Transaction';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
