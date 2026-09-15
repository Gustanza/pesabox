import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class EditGroupScreen extends StatelessWidget {
  const EditGroupScreen({super.key});

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
                title: 'Group Information',
                subtitle: 'Set by your Super Admin',
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
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: AppColors.gold500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your group details are managed by your Super Admin. If anything needs updating, request a change below.',
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
                    _ReadOnlyField(
                      label: 'Group name',
                      value: 'Kijiji Savings Group',
                    ),
                    SizedBox(height: 16),
                    _ReadOnlyField(label: 'Region', value: 'Arusha'),
                    SizedBox(height: 16),
                    _ReadOnlyField(label: 'District', value: 'Arusha Rural'),
                    SizedBox(height: 16),
                    _ReadOnlyField(label: 'Ward', value: 'Kimnyaki'),
                    SizedBox(height: 16),
                    _ReadOnlyField(label: 'Village', value: 'Kijiji'),
                    SizedBox(height: 16),
                    _ReadOnlyField(
                      label: 'Meeting frequency',
                      value: 'Weekly · Mon 10:00 AM',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const OutlineButton(text: 'Request a change'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.ink600,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.ink400,
              ),
            ],
          ),
        ),
      ],
    );
  }
}