import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';

class ReviewRulesScreen extends StatelessWidget {
  const ReviewRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
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
                  HxPageTitle(title: 'Confirm Rules'),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x20),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpace.x20),
                child: Column(
                  children: [
                    RulesSummaryCard(state: state),
                    const SizedBox(height: AppSpace.x16),
                    HxHint(
                      text: tr('These rules will apply to all members once the group is active.'),
                      icon: Icons.check_rounded,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(AppSpace.x20, 0, 20, 24),
              child: HxButton(
                text: tr('Create group'),
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.groupReady);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one rules summary used both here and in Set Group Rules — always
/// driven by the group's real configuration, never hardcoded figures.
class RulesSummaryCard extends StatelessWidget {
  final AppState state;
  const RulesSummaryCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final share = state.shareValue;
    final savings = state.mandatorySavingsAmount;
    final social = state.socialFundContribution;
    final interest = state.loanInterestRate;
    final months = state.maxLoanPeriodMonths;

    return HxSurface(
      child: Column(
        children: [
          _ReviewRow(
            label: tr('Share value'),
            value: share > 0 ? state.money(share) : tr('Not set'),
          ),
          const Divider(height: 24),
          _ReviewRow(
            label: tr('Mandatory savings'),
            value: savings > 0 ? state.money(savings) : tr('Not set'),
          ),
          const Divider(height: 24),
          _ReviewRow(
            label: tr('Social Fund'),
            value: social > 0 ? state.money(social) : tr('Not set'),
          ),
          const Divider(height: 24),
          _ReviewRow(
            label: tr('Loan interest'),
            value: interest > 0 ? '$interest%' : tr('Not set'),
          ),
          const Divider(height: 24),
          _ReviewRow(
            label: tr('Repayment period'),
            value: months > 0
                ? tr('{0} months', [months])
                : tr('Not set'),
          ),
          const Divider(height: 24),
          _ReviewRow(
            label: tr('Max shares'),
            value: '${state.maxShares}',
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr(label),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
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