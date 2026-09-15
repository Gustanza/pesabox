import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class MemberFinancialPositionScreen extends StatelessWidget {
  const MemberFinancialPositionScreen({super.key, this.memberId = 'm1'});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final member = groupMembers.firstWhere(
      (m) => m.id == memberId,
      orElse: () => groupMembers.first,
    );

    final loan = loans.where(
      (l) => l.memberId == memberId && l.status == LoanStatus.active,
    ).firstOrNull;

    final memberFines = fines.where((f) => f.memberId == memberId);
    final finesCharged = memberFines.fold(0.0, (sum, f) => sum + f.amount);
    final finesPaid = memberFines.fold(0.0, (sum, f) => sum + f.amountPaid);

    final mandatorySavings = member.savingsBalance * 0.82;
    final voluntarySavings = member.savingsBalance - mandatorySavings;
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
                title: 'Financial Position',
                subtitle: member.fullName,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Savings',
                children: [
                  _KVRow(
                      label: 'Total savings',
                      value: 'TZS ${_formatNum(member.savingsBalance)}'),
                  _KVRow(
                      label: 'Mandatory',
                      value: 'TZS ${_formatNum(mandatorySavings)}'),
                  _KVRow(
                      label: 'Voluntary',
                      value: 'TZS ${_formatNum(voluntarySavings)}'),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Shares',
                children: [
                  _KVRow(
                      label: 'Shares held',
                      value: '${member.shareCount}'),
                  _KVRow(
                      label: 'Share value',
                      value: 'TZS ${_formatNum(shareValue)}'),
                  _KVRow(
                      label: 'Total share value',
                      value: 'TZS ${_formatNum(totalShareValue)}'),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Social Fund',
                children: [
                  _KVRow(
                      label: 'Contributed',
                      value: 'TZS ${_formatNum(member.socialFundBalance)}'),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Loan',
                children: [
                  _KVRow(
                    label: 'Principal',
                    value: loan != null
                        ? 'TZS ${_formatNum(loan.amount)}'
                        : 'TZS 0',
                  ),
                  _KVRow(
                    label: 'Repaid',
                    value: loan != null
                        ? 'TZS ${_formatNum(loan.amountRepaid)}'
                        : 'TZS 0',
                  ),
                  _KVRow(
                    label: 'Outstanding',
                    value: 'TZS ${_formatNum(member.outstandingLoan)}',
                    valueColor: AppColors.danger,
                  ),
                  if (loan != null)
                    _KVRow(
                      label: 'Next repayment',
                      value: _formatDate(loan.dueDate),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Fines',
                children: [
                  _KVRow(
                      label: 'Charged',
                      value: 'TZS ${_formatNum(finesCharged)}'),
                  _KVRow(
                      label: 'Paid',
                      value: 'TZS ${_formatNum(finesPaid)}'),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

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
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
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
