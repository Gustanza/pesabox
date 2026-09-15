import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class FundsScreen extends StatelessWidget {
  const FundsScreen({super.key});

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
              const AuthHeader(title: 'Funds'),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Savings fund',
                      value: 'TZS 1.3M',
                      color: AppColors.teal800,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      label: 'Share fund',
                      value: 'TZS 480K',
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Social Fund',
                      value: 'TZS 120K',
                      color: AppColors.gold500,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      label: 'Loan fund out',
                      value: 'TZS 630K',
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Fund movement this month',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Column(
                  children: [
                    _KVRow(label: 'Total in', value: 'TZS 8,450,000'),
                    Divider(height: 24),
                    _KVRow(label: 'Total out', value: 'TZS 2,310,000'),
                    Divider(height: 24),
                    _KVRow(
                      label: 'Net movement',
                      value: '+TZS 6,140,000',
                      positive: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'By fund',
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
                child: const Column(
                  children: [
                    _FundRow(
                      icon: Icons.savings_outlined,
                      name: 'Savings',
                      detail: 'TZS 5,000,000 in · TZS 120,000 out',
                      color: AppColors.teal800,
                    ),
                    Divider(height: 1, indent: 56),
                    _FundRow(
                      icon: Icons.pie_chart_outline_rounded,
                      name: 'Shares',
                      detail: 'TZS 2,000,000 in · TZS 0 out',
                      color: AppColors.blue,
                    ),
                    Divider(height: 1, indent: 56),
                    _FundRow(
                      icon: Icons.favorite_outline_rounded,
                      name: 'Social Fund',
                      detail: 'TZS 480,000 in · TZS 60,000 out',
                      color: AppColors.gold500,
                    ),
                    Divider(height: 1, indent: 56),
                    _FundRow(
                      icon: Icons.request_quote_outlined,
                      name: 'Loan fund',
                      detail: 'TZS 970,000 in · TZS 1,600,000 out',
                      color: AppColors.green600,
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final bool positive;

  const _KVRow({required this.label, required this.value, this.positive = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: positive ? AppColors.green600 : AppColors.ink900,
          ),
        ),
      ],
    );
  }
}

class _FundRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String detail;
  final Color color;

  const _FundRow({
    required this.icon,
    required this.name,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, size: 20, color: color),
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
                  detail,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.ink400,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
        ],
      ),
    );
  }
}