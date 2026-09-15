import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

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

  void _switchTab(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      _routes[index],
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => _switchTab(context, 0),
              ),
              _NavItem(
                icon: Icons.group_rounded,
                label: 'Group',
                isActive: currentIndex == 1,
                onTap: () => _switchTab(context, 1),
              ),
              _NavItem(
                icon: Icons.event_rounded,
                label: 'Meetings',
                isActive: currentIndex == 2,
                onTap: () => _switchTab(context, 2),
              ),
              _NavItem(
                icon: Icons.notifications_rounded,
                label: 'Activity',
                isActive: currentIndex == 3,
                onTap: () => _switchTab(context, 3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 4,
                onTap: () => _switchTab(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.teal900 : AppColors.ink400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
