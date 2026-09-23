import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';

import '../../i18n/i18n.dart';

class AwaitingAssignmentScreen extends StatefulWidget {
  const AwaitingAssignmentScreen({super.key});

  @override
  State<AwaitingAssignmentScreen> createState() =>
      _AwaitingAssignmentScreenState();
}

class _AwaitingAssignmentScreenState extends State<AwaitingAssignmentScreen> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    final assigned = await AppState.I.checkGroupAssignment(refresh: true);
    if (!mounted) return;
    setState(() => _checking = false);
    if (!AppState.I.isSignedIn) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.login, (r) => false);
      return;
    }
    if (assigned) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.dashboard, (r) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Still no group assigned yet.'))),
      );
    }
  }

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
              const SizedBox(height: 24),
              Text(
                tr('Hello, {0}', [AppState.I.userName]),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tr('Your group is being set up'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.ink400,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green100,
                      ),
                      child: const Icon(
                        Icons.group_rounded,
                        size: 36,
                        color: AppColors.green600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('Waiting for your group'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('A Super Admin will create your group and assign it to you. Once assigned, you can configure financial rules and start managing members.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                tr('How it works'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 16),
              _TimelineStep(
                number: 1,
                title: tr('Super Admin creates your group'),
                subtitle: tr('Group details are set up in the system'),
                isLast: false,
              ),
              _TimelineStep(
                number: 2,
                title: tr('Group is assigned to you'),
                subtitle: tr('You receive a notification'),
                isLast: false,
              ),
              _TimelineStep(
                number: 3,
                title: tr('You add members'),
                subtitle: tr('Invite members to your group'),
                isLast: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _checking ? null : _checkAgain,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal900,
                    side: const BorderSide(color: AppColors.teal900, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.md,
                    ),
                  ),
                  child: Text(
                    _checking ? tr('Checking…') : tr('Check again'),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await AppState.I.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.login,
                      (r) => false,
                    );
                  },
                  child: Text(
                    tr('Log out'),
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink400,
                    ),
                  ),
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

class _TimelineStep extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final bool isLast;

  const _TimelineStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green600,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: AppColors.green600,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(title),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr(subtitle),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.ink400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
