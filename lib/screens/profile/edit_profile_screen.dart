import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_data.dart';
import '../../services/graphql_client.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import '../../i18n/i18n.dart';

/// Lets an already-logged-in user change their name/email after the fact —
/// the in-app counterpart to [CompleteProfileScreen], which only ever runs
/// once, right after a first-time login. Both hit the same `POST /api/me`
/// via [AppState.completeProfile]; username/phone still can't be changed
/// here, since that's the OTP login identifier.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = AppState.I.user;
    _firstName = TextEditingController(text: user?['firstName'] as String? ?? '');
    _lastName = TextEditingController(text: user?['lastName'] as String? ?? '');
    _email = TextEditingController(text: user?['email'] as String? ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
      if (!mounted) return;
      Navigator.of(context).pop();
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
              AuthHeader(title: tr('Edit profile')),
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
                text: _saving ? tr('Saving…') : tr('Save changes'),
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
