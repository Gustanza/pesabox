import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class LoansListScreen extends StatelessWidget {
  const LoansListScreen({super.key});

  static const List<Color> _avatarColors = [
    AppColors.green600,
    AppColors.blue,
    AppColors.gold500,
  ];

  @override
  Widget build(BuildContext context) {
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
                    child: Text(
                      'Loans',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRouter.recordLoan);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 22,
                        color: AppColors.teal900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SegmentControl(),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Active loans',
                      value: '3',
                      color: AppColors.teal800,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      label: 'Outstanding',
                      value: 'TZS 1,240,000',
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Total loaned',
                      value: 'TZS 2,000,000',
                      color: AppColors.blue,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      label: 'Total repaid',
                      value: 'TZS 1,660,000',
                      color: AppColors.green600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Recent loans',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    _LoanRow(
                      name: 'John Mfinanga',
                      initials: 'JM',
                      amount: 'TZS 480K',
                      months: '3 months',
                      color: _avatarColors[0],
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(AppRouter.loanDetailsPath('l3'));
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _LoanRow(
                      name: 'Asha Mwangi',
                      initials: 'AM',
                      amount: 'TZS 300K',
                      months: '3 months',
                      color: _avatarColors[1],
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(AppRouter.loanDetailsPath('l2'));
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _LoanRow(
                      name: 'Grace Kileo',
                      initials: 'GK',
                      amount: 'TZS 400K',
                      months: '3 months',
                      color: _avatarColors[2],
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(AppRouter.loanDetailsPath('l4'));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentControl extends StatelessWidget {
  const _SegmentControl();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.line.withValues(alpha: 0.5),
        borderRadius: AppRadius.md,
      ),
      child: const Row(
        children: [
          Expanded(child: _Segment(label: 'Overview', active: true)),
          Expanded(child: _Segment(label: 'Applications', active: false)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;

  const _Segment({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.white : Colors.transparent,
        borderRadius: AppRadius.sm,
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? AppColors.ink900 : AppColors.ink400,
        ),
      ),
    );
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
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  final String name;
  final String initials;
  final String amount;
  final String months;
  final Color color;
  final VoidCallback onTap;

  const _LoanRow({
    required this.name,
    required this.initials,
    required this.amount,
    required this.months,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$amount · $months',
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
                borderRadius: AppRadius.sm,
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
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}