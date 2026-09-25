import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x16),
              Padding(
                padding: const EdgeInsets.only(right: AppSpace.x8),
                child: Row(
                  children: [
                    const Expanded(child: HxPageTitle(title: 'My Profile')),
                    HxIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: tr('Edit profile'),
                      onPressed: _editProfile,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x24),
              Center(
                child: Column(
                  children: [
                    HxAvatar(
                      initials: state.initials(state.userName),
                      size: 84,
                    ),
                    const SizedBox(height: AppSpace.x12),
                    Text(
                      state.userName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    if (state.positionLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${state.positionLabel} · ${state.groupName}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.ink400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x24),
              HxSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: tr('Phone'),
                      value: state.userPhone.isNotEmpty
                          ? state.userPhone
                          : tr('Not set'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x24),
              const HxSectionTitle(title: 'Account'),
              const SizedBox(height: AppSpace.x12),
              HxSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    HxMenuRow(
                      icon: Icons.person_outline,
                      title: tr('Edit profile'),
                      color: AppColors.teal900,
                      onTap: _editProfile,
                    ),
                    HxMenuRow(
                      icon: Icons.settings_outlined,
                      title: tr('Settings'),
                      color: AppColors.ink600,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouter.settings);
                      },
                      addDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x24),
              HxButton(
                text: tr('Log out'),
                variant: HxButtonVariant.destructive,
                onPressed: () async {
                  await AppState.I.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.login,
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: AppSpace.x32),
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
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green100,
            ),
            child: Icon(icon, size: 18, color: AppColors.teal800),
          ),
          const SizedBox(width: AppSpace.x12),
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