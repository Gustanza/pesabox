import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

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
              AuthHeader(title: tr('Settings')),
              const SizedBox(height: 20),
              Text(
                tr('Language'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 12),
              const _LanguagePicker(),
              const SizedBox(height: 24),
              Text(
                tr('Notifications'),
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
                    _ToggleRow(title: tr('Meeting reminders'), on: true),
                    Divider(height: 1, indent: 56),
                    _ToggleRow(title: tr('Transaction SMS'), on: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr('Security'),
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
                    _SettingRow(title: tr('Change password')),
                    Divider(height: 1, indent: 56),
                    _SettingRow(title: tr('Change PIN')),
                    Divider(height: 1, indent: 56),
                    _SettingRow(title: tr('Session timeout'), value: '15 min'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr('About'),
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
                    _SettingRow(title: tr('App version'), value: '1.0.0 (MVP)'),
                    Divider(height: 1, indent: 56),
                    _SettingRow(title: tr('SMS sender ID'), value: 'PESABOX'),
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
              tr(title),
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

/// Swahili / English selector. Changing it restarts the app UI in the new
/// language (see PesaBoxApp) and is remembered on the device.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: I18n.locale,
      builder: (context, current, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            for (final option in const [('sw', 'Kiswahili'), ('en', 'English')])
              Expanded(
                child: GestureDetector(
                  onTap: () => I18n.set(option.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: current == option.$1
                          ? AppColors.green600
                          : Colors.transparent,
                      borderRadius: AppRadius.md,
                    ),
                    child: Text(
                      option.$2,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: current == option.$1
                            ? AppColors.white
                            : AppColors.ink600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
              tr(title),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
          ),
          if (value != null) ...[
            Text(
              tr(value!),
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