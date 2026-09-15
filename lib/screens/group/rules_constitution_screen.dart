import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_data.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class RulesConstitutionScreen extends StatelessWidget {
  const RulesConstitutionScreen({super.key});

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
              const AuthHeader(title: 'Rules & Constitution'),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Financial setup',
                children: [
                  _KVRow(
                    label: 'Share value',
                    value: 'TZS ${_fmt(shareValue)}',
                  ),
                  const SizedBox(height: 14),
                  const _KVRow(label: 'Min shares', value: '1'),
                  const SizedBox(height: 14),
                  const _KVRow(label: 'Max shares', value: '5'),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionCard(
                title: 'Social Fund',
                children: [
                  _KVRow(label: 'Amount per meeting', value: 'TZS 2,000'),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Loan settings',
                children: [
                  _KVRow(
                    label: 'Max loan',
                    value: '${maxLoanMultiplier.toInt()}x savings',
                  ),
                  const SizedBox(height: 14),
                  _KVRow(
                    label: 'Interest rate',
                    value: '${interestRate.toInt()}%',
                  ),
                  const SizedBox(height: 14),
                  const _KVRow(label: 'Repayment period', value: '3 months'),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionCard(
                title: 'Fines',
                children: [
                  _KVRow(label: 'Late attendance', value: 'TZS 1,000'),
                  SizedBox(height: 14),
                  _KVRow(label: 'Absence', value: 'TZS 5,000'),
                ],
              ),
              const SizedBox(height: 24),
              OutlineButton(
                text: 'Edit rules',
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.rulesConfig);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double amount) =>
      amount.toInt().toString().replaceAll(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            ',',
          );
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
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
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
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: AppRadius.sm,
          ),
          child: Text(
            value,
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