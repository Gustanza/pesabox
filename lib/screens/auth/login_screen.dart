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
    } catch (_) {
      if (!mounted) return;
      _toast(tr('Could not reach the server. Check your connection.'));
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.teal900, AppColors.teal800],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const BrandMark(size: 64, radius: 18, fontSize: 28),
                const SizedBox(height: 18),
                Text(
                  tr('Welcome to {0}', [kBrandName]),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr("Enter your phone number and we'll text you a code."),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFFBFE0D3),
                  ),
                ),
                const SizedBox(height: 26),
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
        ),
      ),
    );
  }
}
