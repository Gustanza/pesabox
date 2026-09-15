import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

class MeetingActivityScreen extends StatelessWidget {
  const MeetingActivityScreen({super.key, this.meetingId = '12'});

  final String meetingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const ScreenBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meeting Activity',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink900,
                          ),
                        ),
                        Text(
                          'Meeting #012',
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
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.md,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          _ActivityRow(
                            icon: Icons.savings_outlined,
                            color: AppColors.green600,
                            title: 'Contributions',
                            subtitle: 'Record member contributions',
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.recordContributionPath(meetingId),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _ActivityRow(
                            icon: Icons.trending_up_rounded,
                            color: AppColors.blue,
                            title: 'Shares',
                            subtitle: 'Record share purchases',
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.recordSharesPath(meetingId),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _ActivityRow(
                            icon: Icons.people_outline,
                            color: AppColors.gold500,
                            title: 'Social Fund',
                            subtitle: 'Record social fund contributions',
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.recordSocialFundPath(meetingId),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _ActivityRow(
                            icon: Icons.account_balance_outlined,
                            color: AppColors.teal800,
                            title: 'Loans',
                            subtitle: 'View loans & record repayments',
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.loansList);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _ActivityRow(
                            icon: Icons.gavel_outlined,
                            color: AppColors.danger,
                            title: 'Fines',
                            subtitle: 'View fines & add new',
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.finesList);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _ActivityRow(
                            icon: Icons.receipt_long_outlined,
                            color: AppColors.ink600,
                            title: 'Group expense',
                            subtitle: 'Record group expenses',
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.groupExpense);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed(AppRouter.meetingReviewPath(meetingId));
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
                    'Review & close meeting',
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

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
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
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.ink400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}