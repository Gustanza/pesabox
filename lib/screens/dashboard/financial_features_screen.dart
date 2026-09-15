import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class FinancialFeaturesScreen extends StatelessWidget {
  const FinancialFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  const ScreenBackButton(),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Services',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FeatureRow(
                    icon: Icons.savings_rounded,
                    title: 'Savings',
                    description: 'Track member savings contributions',
                    isOn: true,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.pie_chart_rounded,
                    title: 'Shares',
                    description: 'Manage group shares and dividends',
                    isOn: true,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.favorite_rounded,
                    title: 'Social Fund',
                    description: 'Emergency and welfare fund',
                    isOn: true,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.request_quote_rounded,
                    title: 'Loans',
                    description: 'Loan disbursement and tracking',
                    isOn: false,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.gavel_rounded,
                    title: 'Fines',
                    description: 'Track and manage fines',
                    isOn: false,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.card_membership_rounded,
                    title: 'Membership Fee',
                    description: 'One-time registration fees',
                    isOn: false,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.handshake_rounded,
                    title: 'Other Contributions',
                    description: 'Custom contribution types',
                    isOn: false,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.receipt_long_rounded,
                    title: 'Group Expenses',
                    description: 'Track group operational costs',
                    isOn: true,
                  ),
                ],
              ),
            ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.rulesConfig);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green600,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.md,
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isOn;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.isOn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green100,
            ),
            child: Icon(icon, size: 20, color: AppColors.green600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.ink400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOn,
            onChanged: (_) {},
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.green600,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.ink400,
          ),
        ],
      ),
    );
  }
}
