import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';

/// Last step of the setup flow. The group already exists (it was created on
/// the web), so this confirms its real rules; the Mwenyekiti can change them
/// here through the same checked form as Rules & Constitution.
class ReviewRulesScreen extends StatefulWidget {
  const ReviewRulesScreen({super.key});

  @override
  State<ReviewRulesScreen> createState() => _ReviewRulesScreenState();
}

class _ReviewRulesScreenState extends State<ReviewRulesScreen> {
  Future<void> _edit() async {
    await Navigator.of(context).pushNamed(AppRouter.rulesEdit);
    if (mounted) setState(() {}); // AppState.group was refreshed on save
  }

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
                    if (state.can('group.settings')) ...[
                      HxButton(
                        text: tr('Edit rules'),
                        variant: HxButtonVariant.secondary,
                        onPressed: _edit,
                      ),
                      const SizedBox(height: AppSpace.x16),
                    ],
                    HxHint(
                      text: tr('These rules apply to every member. Changes apply to new records only.'),
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
                text: tr('Finish'),
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
    final multiplier = state.maxLoanMultiplier;
    String pct(double v) => v == v.roundToDouble() ? '${v.toInt()}%' : '$v%';

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
            label: tr('Loan interest (flat)'),
            value: pct(interest),
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
            label: tr('Shares per meeting'),
            value: '${state.minShares} – ${state.maxShares}',
          ),
          const Divider(height: 24),
          _ReviewRow(
            label: tr('Max loan'),
            value: multiplier > 0
                ? tr('{0}× savings + shares', [multiplier == multiplier.roundToDouble() ? multiplier.toInt() : multiplier])
                : tr('No limit'),
          ),
          const Divider(height: 24),
          _ReviewRow(
            label: tr('Services'),
            value: state.enabledServices.map(tr).join(', '),
          ),
          for (final r in state.fineReasons) ...[
            const Divider(height: 24),
            _ReviewRow(
              label: tr('Fine: {0}', [r['reason'] ?? '']),
              value: state.money((r['amount'] as num?) ?? 0),
            ),
          ],
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
        Flexible(
          child: Text(
            tr(label),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.ink400,
            ),
          ),
        ),
        const SizedBox(width: 12),
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