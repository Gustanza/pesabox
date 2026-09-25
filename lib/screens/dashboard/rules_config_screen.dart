import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import 'review_rules_screen.dart';

import '../../i18n/i18n.dart';

class RulesConfigScreen extends StatelessWidget {
  const RulesConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x24, 20, 0),
              child: Row(
                children: [
                  HxBackButton(),
                  const SizedBox(width: AppSpace.x12),
                  HxPageTitle(title: 'Set Group Rules'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.x20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Your group\'s financial rules are shown below. These limits drive lending, savings and fines for every member.'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpace.x16),
                    RulesSummaryCard(state: AppState.I),
                    const SizedBox(height: AppSpace.x16),
                    HxHint(
                      text: tr('Only a Super Admin can change these rules. Review them now — changes later require a Super Admin.'),
                      icon: Icons.lock_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}