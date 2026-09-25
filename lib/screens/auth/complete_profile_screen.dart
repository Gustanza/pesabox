import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/graphql_client.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';
import 'auth_widgets.dart';
import '../../i18n/i18n.dart';

/// Step 3 of the OTP flow: shown right after a first-time login, when the
/// backend's `firstName == ""` on the login response says this account was
/// just auto-created and has no name on file yet (see
/// [AppState.needsProfileCompletion]). Username/phone can't be changed
/// here — that's the OTP login identifier the account was looked up by.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstName = _firstName.text.trim();
    if (firstName.isEmpty) {
      setState(() => _error = tr('First name is required'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppState.I.completeProfile(
        firstName: firstName,
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
      );
      final hasGroup = await AppState.I.checkGroupAssignment();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        hasGroup ? AppRouter.dashboard : AppRouter.awaitingAssignment,
        (r) => false,
      );
    } on GraphQLException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = tr('Could not save your profile. Try again.'));
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
              Text(
                tr('Complete your profile'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('Just your name so we know who you are.'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.ink600,
                ),
              ),
              const SizedBox(height: 22),
              AuthTextField(
                label: 'First name',
                hint: 'Jane',
                controller: _firstName,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Last name',
                hint: 'Doe',
                requiredField: false,
                controller: _lastName,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Email',
                hint: 'jane@example.com',
                requiredField: false,
                keyboardType: TextInputType.emailAddress,
                controller: _email,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                text: _saving ? tr('Saving…') : tr('Continue'),
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
