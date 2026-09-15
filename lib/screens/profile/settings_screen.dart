import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              const AuthHeader(title: 'Settings'),
              const SizedBox(height: 20),
              Text(
                'Notifications',
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
                    _ToggleRow(title: 'Meeting reminders', on: true),
                    Divider(height: 1, indent: 56),
                    _ToggleRow(title: 'Transaction SMS', on: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Security',
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
                    _SettingRow(title: 'Change password'),
                    Divider(height: 1, indent: 56),
                    _SettingRow(title: 'Change PIN'),
                    Divider(height: 1, indent: 56),
                    _SettingRow(title: 'Session timeout', value: '15 min'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'About',
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
                    _SettingRow(title: 'App version', value: '1.0.0 (MVP)'),
                    Divider(height: 1, indent: 56),
                    _SettingRow(title: 'SMS sender ID', value: 'PESABOX'),
                  ],
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

class _ToggleRow extends StatelessWidget {
  final String title;
  final bool on;

  const _ToggleRow({required this.title, required this.on});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
          ),
          Switch(
            value: on,
            onChanged: (_) {},
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.green600,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.ink400,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String? value;

  const _SettingRow({required this.title, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
          ),
          if (value != null) ...[
            Text(
              value!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.ink600,
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
        ],
      ),
    );
  }
}