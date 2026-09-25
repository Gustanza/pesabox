import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';

class FinancialFeaturesScreen extends StatelessWidget {
  const FinancialFeaturesScreen({super.key});

  // (icon, service name as stored in enabledServices — null = always on, title, subtitle)
  static const List<(IconData, String?, String, String)> _features = [
    (Icons.savings_rounded, 'Mandatory Savings', 'Savings', 'Track member savings contributions'),
    (Icons.pie_chart_rounded, 'Shares', 'Shares', 'Manage group shares and dividends'),
    (Icons.favorite_rounded, 'Social Fund', 'Social Fund', 'Emergency and welfare fund'),
    (Icons.request_quote_rounded, 'Loans', 'Loans', 'Loan disbursement and tracking'),
    (Icons.gavel_rounded, 'Fines', 'Fines', 'Track and manage fines'),
    (Icons.card_membership_rounded, 'Membership Fee', 'Membership Fee', 'One-time registration fees'),
    (Icons.receipt_long_rounded, null, 'Group Expenses', 'Track group operational costs'),
  ];

  static bool _on(String? service) {
    if (service == null) return true;
    final state = AppState.I;
    return service == 'Mandatory Savings' ? state.savingsEnabled : state.serviceEnabled(service);
  }

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
                  HxPageTitle(title: 'Financial Services'),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
                children: [
                  Text(
                    tr('These are the services your group uses. The Mwenyekiti can switch them on or off in the group rules.'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpace.x16),
                  for (final f in _features) ...[
                    HxSurface(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.x16, vertical: AppSpace.x12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _on(f.$2) ? AppColors.green100 : AppColors.line,
                            ),
                            child: Icon(
                              _on(f.$2) ? Icons.check_rounded : Icons.close_rounded,
                              size: 20,
                              color: _on(f.$2) ? AppColors.teal800 : AppColors.ink400,
                            ),
                          ),
                          const SizedBox(width: AppSpace.x12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(f.$3),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _on(f.$2) ? tr(f.$4) : tr('Switched off'),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.ink400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.x12),
                  ],
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(AppSpace.x20, AppSpace.x12, 20, 24),
              child: HxButton(
                text: tr('Next'),
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.rulesConfig);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}