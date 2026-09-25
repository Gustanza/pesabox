import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

import '../../i18n/i18n.dart';

/// Premium floating pill bar — the app's signature navigation treatment.
///
/// A softly-raised rounded surface floats above the cream scaffold; the
/// active tab wears a green capsule (pressed feel without neon fills), with
/// weight + colour echoing motion between tabs. Labels stay on for all five
/// tabs so users never stop being sure where they are.
class DashboardNavBar extends StatelessWidget {
  final int currentIndex;

  const DashboardNavBar({super.key, this.currentIndex = 0});

  static const List<String> _routes = [
    AppRouter.dashboard,
    AppRouter.groupInfo,
    AppRouter.meetingsList,
    AppRouter.transactionsList,
    AppRouter.profile,
  ];

  static const List<_TabDef> _tabs = [
    _TabDef(icon: Icons.home_rounded, key: 'Home'),
    _TabDef(icon: Icons.group_rounded, key: 'Group'),
    _TabDef(icon: Icons.event_rounded, key: 'Meetings'),
    _TabDef(icon: Icons.receipt_long_rounded, key: 'Activity'),
    _TabDef(icon: Icons.person_rounded, key: 'Profile'),
  ];

  void _switchTab(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      _routes[index],
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(AppSpace.x16, 0, AppSpace.x16, AppSpace.x12),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.x8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadow.nav,
        ),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            return Expanded(
              child: _PillItem(
                def: _tabs[i],
                isActive: i == currentIndex,
                onTap: () => _switchTab(context, i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final String key;

  const _TabDef({required this.icon, required this.key});
}

class _PillItem extends StatelessWidget {
  final _TabDef def;
  final bool isActive;
  final VoidCallback onTap;

  const _PillItem({
    required this.def,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.teal900 : AppColors.ink400;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x8,
          vertical: AppSpace.x8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.green100 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(def.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              tr(def.key),
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}