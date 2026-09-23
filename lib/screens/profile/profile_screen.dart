import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../dashboard/dashboard_nav_bar.dart';
import '../../i18n/i18n.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Pushes the edit screen and rebuilds on return so the updated
  /// name/email (saved via [AppState.completeProfile]) show up immediately
  /// — this screen reads straight off the [AppState] singleton rather than
  /// a listenable, so nothing else would trigger that refresh.
  Future<void> _editProfile() async {
    await Navigator.of(context).pushNamed(AppRouter.editProfile);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('My Profile'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                  IconButton(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.ink600),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: AppColors.teal900,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tr(state.initials(state.userName)),
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr(state.userName),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.positionLabel} · ${state.groupName}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: tr('Phone'),
                      value: state.userPhone.isNotEmpty
                          ? state.userPhone
                          : tr('Not set'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: tr('Member since'),
                      value: 'Mar 2026',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr('Account'),
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
                    _AccountRow(
                      icon: Icons.person_outline,
                      title: tr('Edit profile'),
                      color: AppColors.teal900,
                      onTap: _editProfile,
                    ),
                    const Divider(height: 1, indent: 56),
                    _AccountRow(
                      icon: Icons.help_outline_rounded,
                      title: tr('Help'),
                      color: AppColors.blue,
                    ),
                    const Divider(height: 1, indent: 56),
                    _AccountRow(
                      icon: Icons.settings_outlined,
                      title: tr('Settings'),
                      color: AppColors.ink600,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouter.settings);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await AppState.I.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.login,
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.md,
                    ),
                  ),
                  child: Text(
                    tr('Log out'),
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
      bottomNavigationBar: const DashboardNavBar(currentIndex: 4),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green100,
            ),
            child: Icon(icon, size: 18, color: AppColors.green600),
          ),
          const SizedBox(width: 12),
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

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _AccountRow({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
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
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
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
            const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}