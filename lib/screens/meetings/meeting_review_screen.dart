import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class MeetingReviewScreen extends StatelessWidget {
  const MeetingReviewScreen({super.key, this.meetingId = '12'});

  final String meetingId;

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
              AuthHeader(
                title: 'Review & Close',
                subtitle: 'Meeting #012',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Attendance',
                children: const [
                  _KVRow(label: 'Present', value: '24'),
                  _KVRow(label: 'Late', value: '2'),
                  _KVRow(label: 'Absent', value: '1'),
                  _KVRow(label: 'Excused', value: '1'),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Money received',
                children: const [
                  _KVRow(label: 'Savings', value: 'TZS 240,000'),
                  _KVRow(label: 'Shares', value: 'TZS 60,000'),
                  _KVRow(label: 'Social Fund', value: 'TZS 12,000'),
                  _KVRow(label: 'Fines', value: 'TZS 5,000'),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Loans',
                children: const [
                  _KVRow(label: 'Disbursed', value: 'TZS 500,000'),
                  _KVRow(label: 'Repaid', value: 'TZS 150,000'),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Expenses',
                children: const [
                  _KVRow(
                    label: 'Total expenses',
                    value: 'TZS 15,000',
                    valueColor: AppColors.danger,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.meetingsList,
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.md,
                    ),
                  ),
                  child: Text(
                    'Confirm & close meeting',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
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
        borderRadius: AppRadius.md,
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