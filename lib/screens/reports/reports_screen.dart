import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import 'report_view_screen.dart';

import '../../i18n/i18n.dart';

/// Opens the live report for one dataset (real data, date range, downloads).
void _openReport(BuildContext context, String key) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ReportViewScreen(defKey: key)),
  );
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AuthHeader(title: tr('Reports')),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    _ReportRow(
                      icon: Icons.file_download_outlined,
                      title: tr('Export reports'),
                      color: AppColors.green600,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouter.exportReport);
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _ReportRow(
                      icon: Icons.insert_chart_outlined_rounded,
                      title: tr('Financial Summary'),
                      color: AppColors.teal800,
                      onTap: () => _openReport(context, 'group-summary'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _ReportRow(
                      icon: Icons.savings_outlined,
                      title: tr('Savings Report'),
                      onTap: () => _openReport(context, 'savings'),
                      color: AppColors.green600,
                    ),
                    const Divider(height: 1, indent: 56),
                    _ReportRow(
                      icon: Icons.pie_chart_outline_rounded,
                      title: tr('Shares Report'),
                      onTap: () => _openReport(context, 'shares'),
                      color: AppColors.info,
                    ),
                    const Divider(height: 1, indent: 56),
                    _ReportRow(
                      icon: Icons.favorite_outline_rounded,
                      title: tr('Social Fund Report'),
                      onTap: () => _openReport(context, 'social-fund'),
                      color: AppColors.gold500,
                    ),
                    const Divider(height: 1, indent: 56),
                    _ReportRow(
                      icon: Icons.request_quote_outlined,
                      title: tr('Loans Report'),
                      onTap: () => _openReport(context, 'loans'),
                      color: AppColors.teal700,
                    ),
                    const Divider(height: 1, indent: 56),
                    _ReportRow(
                      icon: Icons.gavel_outlined,
                      title: tr('Fines Report'),
                      onTap: () => _openReport(context, 'fines-outstanding'),
                      color: AppColors.danger,
                    ),
                    const Divider(height: 1, indent: 56),
                    _ReportRow(
                      icon: Icons.receipt_long_outlined,
                      title: tr('Expenses Report'),
                      onTap: () => _openReport(context, 'expenses'),
                      color: AppColors.ink600,
                    ),
                    const Divider(height: 1, indent: 56),
                    _ReportRow(
                      icon: Icons.account_balance_outlined,
                      title: tr('Group Statement'),
                      onTap: () => Navigator.of(context).pushNamed(AppRouter.groupStatement),
                      color: AppColors.green600,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _ReportRow({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(title),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}