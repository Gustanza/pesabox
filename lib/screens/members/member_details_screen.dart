import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class MemberDetailsScreen extends StatelessWidget {
  const MemberDetailsScreen({super.key, this.memberId = 'm1'});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final member = groupMembers.firstWhere(
      (m) => m.id == memberId,
      orElse: () => groupMembers.first,
    );

    final memberTransactions = transactions
        .where((t) => t.memberId == memberId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final shareValueEach = shareValue;
    final totalShares = member.shareCount * shareValueEach;

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
                  ScreenBackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.fullName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                          ),
                        ),
                        Text(
                          'Member #${member.id.replaceFirst('m', '').padLeft(3, '0')}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.ink400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.editMemberPath(member.id),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.ink700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ProfileCard(member: member),
              const SizedBox(height: 20),
              Text(
                'Financial position',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Savings',
                      value: 'TZS ${_formatK(member.savingsBalance)}',
                      color: AppColors.green600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      label: 'Shares ${member.shareCount}',
                      value: 'TZS ${_formatK(totalShares)}',
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Social Fund',
                      value: 'TZS ${_formatK(member.socialFundBalance)}',
                      color: AppColors.gold500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      label: 'Outstanding loan',
                      value: 'TZS ${_formatK(member.outstandingLoan)}',
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.memberFinancialPositionPath(member.id),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View full financial position',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal900,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.teal900,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Recent transactions',
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
                ...memberTransactions.take(3).map(
                      (tx) => _TransactionRow(transaction: tx),
                    ),
              const SizedBox(height: 16),
              OutlineButton(
                text: 'View statement',
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.memberStatementPath(member.id),
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

  static String _formatK(double amount) {
    if (amount >= 1000) {
      final k = amount / 1000;
      return k == k.roundToDouble()
          ? '${k.toInt()}K'
          : '${k.toStringAsFixed(0)}K';
    }
    return amount.toInt().toString();
  }
}

class _ProfileCard extends StatelessWidget {
  final Member member;
  const _ProfileCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.green600,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              member.initials,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.phone,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.ink400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined ${_formatDate(member.joinedAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.ink400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Active',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.teal800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
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
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  const _TransactionRow({required this.transaction});

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
