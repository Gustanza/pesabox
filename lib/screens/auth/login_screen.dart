import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';
import 'auth_widgets.dart';

import '../../i18n/i18n.dart';
import '../../brand.dart';

/// The only way in: a phone number, then an OTP. There's no separate
/// "create account" screen — the backend creates the account automatically
/// the first time someone verifies a code for a phone number it hasn't seen
/// before, so this same screen serves both new and returning users.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _phone = '';
  bool _loading = false;

  Future<void> _continue() async {
    final phone = _phone.trim();
    if (phone.isEmpty) {
      _toast(tr('Enter your phone number.'));
      return;
    }
    setState(() => _loading = true);
    try {
      final sent = await AuthService.requestOtp(phone);
      if (!mounted) return;
      if (!sent) {
        setState(() => _loading = false);
        _toast(tr('Unable to send a code right now.'));
        return;
      }
      Navigator.of(context).pushNamed(AppRouter.otp, arguments: phone);
    } catch (e) {
      if (!mounted) return;
      _toast(AuthService.refusalMessage(e) ?? tr('Could not reach the server. Check your connection.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.lg,
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: BrandMark(size: 72, radius: 20, fontSize: 30),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr('Welcome to {0}', [kBrandName]),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr("Enter your phone number and we'll text you a code."),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.ink600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    PhoneInputField(
                      onChanged: (value) => _phone = value,
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      text: _loading ? tr('Sending code…') : tr('Continue'),
                      onPressed: _loading ? null : _continue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}