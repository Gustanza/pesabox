import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';

class GroupAssignedScreen extends StatelessWidget {
  const GroupAssignedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    final name = state.groupName.isEmpty ? tr('Your group') : state.groupName;
    final location = state.groupLocation.isNotEmpty
        ? [state.groupType, state.groupLocation].join(' · ')
        : state.groupType;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green600,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 28,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr('Your group is ready!'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                tr('Your group has been created and assigned to you. Review the details below and set up your financial features.'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.ink600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
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
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              location,
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
              const SizedBox(height: AppSpace.x12),
              HxSurface(
                padding: const EdgeInsets.all(AppSpace.x16),
child: Column(
                    children: [
                      _KVRow(label: tr('Group type'), value: state.groupType),
                      const SizedBox(height: AppSpace.x12),
                      _KVRow(
                          label: tr('Location'),
                          value: state.groupLocation),
                      const SizedBox(height: AppSpace.x12),
                      _KVRow(
                        label: tr('Assigned admin'),
                        value: tr('You (Group Admin)'),
                      ),
                    ],
                  ),
              ),
              const SizedBox(height: AppSpace.x16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.ink400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('You can edit these details later from the group settings.'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink400,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              HxButton(
                text: tr('Set up financial features'),
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.financialFeatures);
                },
              ),
              const SizedBox(height: AppSpace.x32),
            ],
          ),
        ),
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;

  const _KVRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr(label),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.ink400,
          ),
        ),
        Text(
          tr(value),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink900,
          ),
        ),
      ],
    );
  }
}