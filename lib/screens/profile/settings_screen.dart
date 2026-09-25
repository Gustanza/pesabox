import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';
import '../../services/app_data.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x16),
              HxHeader(title: tr('Settings')),
              const SizedBox(height: AppSpace.x20),
              const HxSectionTitle(title: 'Language'),
              const SizedBox(height: AppSpace.x12),
              const _LanguagePicker(),
              const SizedBox(height: AppSpace.x24),
              const HxSectionTitle(title: 'Notifications'),
              const SizedBox(height: AppSpace.x12),
              HxSurface(
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpace.x16),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.teal100,
                        ),
                        child: const Icon(
                          Icons.sms_outlined,
                          size: 20,
                          color: AppColors.teal800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            right: AppSpace.x16, top: AppSpace.x16, bottom: AppSpace.x16),
                        child: Text(
                          tr('SMS alerts are sent automatically to your phone.'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.ink600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x24),
              const HxSectionTitle(title: 'About'),
              const SizedBox(height: AppSpace.x12),
              HxSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AboutRow(label: tr('App version'), value: '1.0.0 (MVP)'),
                    const Divider(height: 1, indent: 56),
                    // Sender ID comes from the server (BEEM_SENDER_ID or the
                    // approved default) — never hard-code it here.
                    FutureBuilder<String>(
                      future: AppState.I.fetchSmsSenderId(),
                      builder: (context, snap) => _AboutRow(
                        label: tr('SMS sender ID'),
                        value: snap.data ?? '…',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tr(label),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
          ),
          Text(
            tr(value),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.ink600,
            ),
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
      builder: (context, current, _) => HxSurface(
        padding: const EdgeInsets.all(AppSpace.x4),
        child: Row(
          children: [
            for (final option in const [('sw', 'Kiswahili'), ('en', 'English')])
              Expanded(
                child: Pressable(
                  onTap: () => I18n.set(option.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
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