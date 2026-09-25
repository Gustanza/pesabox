import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';

class GroupReadyScreen extends StatelessWidget {
  const GroupReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final name = state.groupName.isEmpty ? tr('Your group') : state.groupName;
    final subtitle = state.groupLocation.isNotEmpty
        ? [state.groupType, state.groupLocation].join(' · ')
        : state.groupType;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            children: [
              const SizedBox(height: 64),
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green600,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 34,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr('Group Created Successfully!'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                tr('Your group rules have been saved. You can now start adding members and managing your group.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.ink600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              HxSurface(
                padding: const EdgeInsets.all(AppSpace.x16),
                child: Row(
                  children: [
                    HxAvatar(initials: state.initials(name), size: 44),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.ink400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x32),
              HxButton(
                text: tr('Add members'),
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.addMember);
                },
              ),
              const SizedBox(height: AppSpace.x12),
              HxButton(
                text: tr('View group'),
                variant: HxButtonVariant.secondary,
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.groupInfo);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}