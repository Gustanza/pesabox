import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/app_router.dart';
import '../../services/app_data.dart';
import '../../services/graphql_client.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../auth/auth_widgets.dart';

import '../../i18n/i18n.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _MemberFormData {
  final nameController = TextEditingController();
  final numberController = TextEditingController();
  String phone = '';
  String? gender;

  void dispose() {
    nameController.dispose();
    numberController.dispose();
  }
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final List<_MemberFormData> _forms = [_MemberFormData()];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final f in _forms) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    for (var i = 0; i < _forms.length; i++) {
      final f = _forms[i];
      if (f.nameController.text.trim().isEmpty ||
          f.phone.trim().isEmpty ||
          f.gender == null) {
        setState(() => _error =
            tr('Fill in name, phone and gender for member {0}.', [i + 1]));
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    var addedAny = false;
    try {
      for (var i = 0; i < _forms.length; i++) {
        final f = _forms[i];
        final phone = f.phone.trim();

        final verified = await _verifyPhone(phone, memberNumber: i + 1);
        if (!verified) {
          setState(() => _error ??= tr(
                  'Phone not verified — member {0} was not added.', [i + 1]) +
              (addedAny ? tr(' Earlier members were.') : ''));
          return;
        }

        final parts = f.nameController.text.trim().split(RegExp(r'\s+'));
        final firstName = parts.first;
        final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        await AppState.I.createMember(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          gender: f.gender!,
          memberNumber: f.numberController.text.trim(),
        );
        addedAny = true;
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.membersList,
        (route) => route.isFirst,
      );
    } on GraphQLException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = tr('Could not save members. Check your connection.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Requests an OTP for [phone], then shows a bottom sheet for entering
  /// it. Returns true once the backend has confirmed the code.
  Future<bool> _verifyPhone(String phone, {required int memberNumber}) async {
    try {
      await AppState.I.requestMemberOtp(phone);
    } on GraphQLException catch (e) {
      if (mounted) setState(() => _error = e.message);
      return false;
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = tr('Could not send the code. Check your connection.'),
        );
      }
      return false;
    }

    if (!mounted) return false;
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _MemberOtpSheet(phone: phone, memberNumber: memberNumber),
    );
    return verified ?? false;
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
              const SizedBox(height: 16),
              AuthHeader(
                title: tr('Add Members'),
                subtitle: tr('Enter member details manually.'),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < _forms.length; i++) ...[
                _MemberForm(memberNumber: i + 1, data: _forms[i]),
                const SizedBox(height: 20),
              ],
              GestureDetector(
                onTap: () {
                  setState(() => _forms.add(_MemberFormData()));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: AppColors.green600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr('Add another member'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  tr(_error!),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                text: _saving ? tr('Saving…') : tr('Save members'),
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gold100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.gold500,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr("We'll text each member a code to confirm their number before they're added."),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.ink700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberForm extends StatefulWidget {
  final int memberNumber;
  final _MemberFormData data;

  const _MemberForm({required this.memberNumber, required this.data});

  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('Member {0}', [widget.memberNumber]),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink900,
          ),
        ),
        const SizedBox(height: 12),
        AuthTextField(
          label: tr('Full name'),
          hint: tr('Enter full name'),
          controller: widget.data.nameController,
        ),
        const SizedBox(height: 18),
        PhoneInputField(
          onChanged: (value) => widget.data.phone = value,
        ),
        const SizedBox(height: 18),
        _GenderDropdown(
          value: widget.data.gender,
          onChanged: (v) => setState(() => widget.data.gender = v),
        ),
        const SizedBox(height: 18),
        AuthTextField(
          label: tr('Member number'),
          hint: tr('e.g. 001'),
          requiredField: false,
          controller: widget.data.numberController,
        ),
      ],
    );
  }
}


class _GenderDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _GenderDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: tr('Gender'),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink700,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: GoogleFonts.inter(color: AppColors.danger),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(
            tr('Select gender'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.ink400,
            ),
          ),
          items: [
            DropdownMenuItem(value: 'Male', child: Text(tr('Male'))),
            DropdownMenuItem(value: 'Female', child: Text(tr('Female'))),
          ],
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink900),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.line, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.green600, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

const int _memberOtpLength = 4;

/// Bottom sheet that verifies one member's phone number before Add Member
/// creates that member. Pops `true` once verified, `false`/`null` if the
/// admin backs out.
class _MemberOtpSheet extends StatefulWidget {
  final String phone;
  final int memberNumber;

  const _MemberOtpSheet({required this.phone, required this.memberNumber});

  @override
  State<_MemberOtpSheet> createState() => _MemberOtpSheetState();
}

class _MemberOtpSheetState extends State<_MemberOtpSheet> {
  final List<TextEditingController> _controllers =
      List.generate(_memberOtpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_memberOtpLength, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  String? _error;

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await AppState.I.requestMemberOtp(widget.phone);
    } on GraphQLException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = tr('Could not resend the code.'));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_code.length < _memberOtpLength) {
      setState(() => _error = tr('Enter the {0}-digit code', [_memberOtpLength]));
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await AppState.I.verifyMemberOtp(widget.phone, _code);
      if (mounted) Navigator.of(context).pop(true);
    } on GraphQLException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = tr('Invalid or expired code'));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr('Verify member {0}\'s phone', [widget.memberNumber]),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text: tr("We've texted a {0}-digit code to\n", [_memberOtpLength]),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.ink600,
                ),
                children: [
                  TextSpan(
                    text: widget.phone,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                for (var i = 0; i < _memberOtpLength; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.line,
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty &&
                                i < _controllers.length - 1) {
                              FocusScope.of(context)
                                  .requestFocus(_focusNodes[i + 1]);
                            } else if (value.isEmpty && i > 0) {
                              FocusScope.of(context)
                                  .requestFocus(_focusNodes[i - 1]);
                            }
                            if (_error != null) setState(() => _error = null);
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _resending ? null : _resend,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    _resending ? tr('Resending…') : tr('Resend code'),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green600,
                    ),
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  tr(_error!),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: HxButton(
                    text: tr('Cancel'),
                    variant: HxButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: _verifying ? tr('Verifying…') : tr('Verify'),
                    onPressed: _verifying ? null : _verify,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
