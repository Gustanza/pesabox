import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';
import 'auth_widgets.dart';

/// App entry point. Before showing the "Get started" welcome UI, this tries
/// to restore a previously persisted session (see [AppState.restore]) so a
/// restarted app doesn't force the user through phone+OTP again — if a
/// session is found it silently routes straight into the group (or the
/// "awaiting assignment" screen) instead.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final restored = await AppState.I.restore();
    if (!mounted) return;
    if (!restored) {
      setState(() => _checkingSession = false);
      return;
    }
    final hasGroup = await AppState.I.checkGroupAssignment();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      hasGroup ? AppRouter.dashboard : AppRouter.awaitingAssignment,
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.teal900, AppColors.teal800],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const Spacer(),
                const BrandMark(size: 88, radius: 24, fontSize: 40),
                const SizedBox(height: 22),
                Text(
                  'PesaBox',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your group,\nsecure your future.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.5,
                    color: const Color(0xFFBFE0D3),
                  ),
                ),
                const Spacer(),
                if (_checkingSession)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.white),
                      ),
                    ),
                  )
                else ...[
                  PrimaryButton(
                    text: 'Get started',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRouter.login),
                  ),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
