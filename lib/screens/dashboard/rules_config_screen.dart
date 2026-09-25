import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import 'review_rules_screen.dart';

import '../../i18n/i18n.dart';

class RulesConfigScreen extends StatefulWidget {
  const RulesConfigScreen({super.key});

  @override
  State<RulesConfigScreen> createState() => _RulesConfigScreenState();
}

class _RulesConfigScreenState extends State<RulesConfigScreen> {
  @override
  Widget build(BuildContext context) {
    final canEdit = AppState.I.can('group.settings');
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
                    if (canEdit) ...[
                      HxButton(
                        text: tr('Edit rules'),
                        variant: HxButtonVariant.secondary,
                        onPressed: () async {
                          await Navigator.of(context).pushNamed(AppRouter.rulesEdit);
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(height: AppSpace.x16),
                    ],
                    HxHint(
                      text: canEdit
                          ? tr('You can change these rules now or later from Rules & Constitution. Changes apply to new records only.')
                          : tr('The Mwenyekiti can change these rules.'),
                      icon: Icons.lock_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, 20, 24),
              child: HxButton(
                text: tr('Next'),
                onPressed: () => Navigator.pushNamed(context, AppRouter.reviewRules),
              ),
            ),
          ],
        ),
      ),
    );
  }
}