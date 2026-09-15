import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class GroupStatementScreen extends StatelessWidget {
  const GroupStatementScreen({super.key});

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
              const AuthHeader(
                title: 'Group Statement',
                subtitle: 'Kijiji Savings Group',
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.teal900, AppColors.teal800],
                  ),
                  borderRadius: AppRadius.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CYCLE 1',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3 Mar 2026 – 2 Mar 2027',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InverseStat(
                            label: 'Meetings held',
                            value: '12 / 52',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InverseStat(
                            label: 'Share value',
                            value: 'TZS 10,000',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                    _KVRow(label: 'Total contributions', value: 'TZS 2,160,000'),
                    Divider(height: 24),
                    _KVRow(label: 'Total shares', value: 'TZS 480,000'),
                    Divider(height: 24),
                    _KVRow(label: 'Social fund', value: 'TZS 120,000'),
                    Divider(height: 24),
                    _KVRow(label: 'Loans disbursed', value: 'TZS 2,000,000'),
                    Divider(height: 24),
                    _KVRow(label: 'Loans outstanding', value: 'TZS 630,000'),
                    Divider(height: 24),
                    _KVRow(label: 'Loans repaid', value: 'TZS 1,370,000'),
                    Divider(height: 24),
                    _KVRow(label: 'Total fines', value: 'TZS 6,000'),
                    Divider(height: 24),
                    _KVRow(
                      label: 'Total expenses',
                      value: 'TZS 8,000',
                      strong: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlineButton(
                text: 'Share statement',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group statement shared via SMS'),
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

class _InverseStat extends StatelessWidget {
  final String label;
  final String value;

  const _InverseStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
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
  final bool strong;

  const _KVRow({required this.label, required this.value, this.strong = false});

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
            fontSize: strong ? 15 : 13,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.ink900,
          ),
        ),
      ],
    );
  }
}