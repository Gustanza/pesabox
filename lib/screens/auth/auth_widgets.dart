import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

import '../../i18n/i18n.dart';
import '../../brand.dart';

/// Note: this file keeps the legacy shared widget names so existing screens
/// keep compiling — every widget now delegates to the `lib/ui` kit so the
/// whole app inherits the unified treatment automatically.

class BrandMark extends StatelessWidget {
  final double size;
  final double radius;
  final double fontSize;

  const BrandMark({
    super.key,
    this.size = 88,
    this.radius = 24,
    this.fontSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green500, AppColors.gold500],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        kBrandName[0],
        style: GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.teal900,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool success;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    return HxButton(
      text: text,
      onPressed: onPressed,
      variant: HxButtonVariant.primary,
      loading: loading,
      success: success,
    );
  }
}

class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const OutlineButton({super.key, required this.text, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return HxButton(
      text: text,
      onPressed: onPressed,
      variant: HxButtonVariant.secondary,
      loading: loading,
    );
  }
}

class ScreenBackButton extends StatelessWidget {
  final bool dark;
  final VoidCallback? onPressed;

  const ScreenBackButton({super.key, this.dark = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return HxBackButton(dark: dark, onPressed: onPressed);
  }
}

class AuthHeader extends StatelessWidget {
  final bool dark;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const AuthHeader({
    super.key,
    this.dark = false,
    this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return HxHeader(
      dark: dark,
      title: title,
      subtitle: subtitle,
      onBack: onBack,
      actions: trailing == null ? null : [trailing!],
    );
  }
}

class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final bool requiredField;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? errorText;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.requiredField = true,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return HxField(
      label: tr(label),
      hint: tr(hint),
      obscure: obscure,
      required: requiredField,
      keyboardType: keyboardType,
      controller: controller,
      onChanged: onChanged,
      errorText: errorText == null ? null : tr(errorText!),
    );
  }
}

/// Shared phone number field for every phone input in the app (login,
/// Add Member, ...) — a country-code selector (Tanzania by default) plus a
/// national-number field, instead of a plain text box someone has to type
/// "+255" or "255" into by hand. [onChanged] always receives the full
/// international number without a leading "+" (e.g. "255712345678"), the
/// same shape the backend and SMTZ already expect everywhere else.
class PhoneInputField extends StatelessWidget {
  final String label;
  final bool requiredField;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  /// Pre-fills an existing number (e.g. on an edit screen) — any format is
  /// fine ("+255 754 123 456", "255754123456", ...), whitespace is stripped
  /// before handing it to the picker.
  final String? initialPhone;

  const PhoneInputField({
    super.key,
    this.label = 'Phone number',
    this.requiredField = true,
    required this.onChanged,
    this.controller,
    this.initialPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HxFieldLabel(text: tr(label), required: requiredField),
        const SizedBox(height: AppSpace.x8),
        InternationalPhoneNumberInput(
          onInputChanged: (number) =>
              onChanged((number.phoneNumber ?? '').replaceFirst('+', '')),
          selectorConfig: const SelectorConfig(
            selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
            setSelectorButtonAsPrefixIcon: true,
            leadingPadding: 12,
            useBottomSheetSafeArea: true,
          ),
          initialValue: PhoneNumber(
            isoCode: 'TZ',
            phoneNumber: initialPhone?.replaceAll(RegExp(r'\s'), ''),
          ),
          textFieldController: controller,
          formatInput: true,
          autoValidateMode: AutovalidateMode.disabled,
          ignoreBlank: false,
          keyboardType: TextInputType.phone,
          textStyle:
              GoogleFonts.inter(fontSize: 15, color: AppColors.ink900),
          selectorTextStyle:
              GoogleFonts.inter(fontSize: 15, color: AppColors.ink900),
          inputDecoration: InputDecoration(
            hintText: tr('Phone number'),
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.ink400),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.sm,
              borderSide: const BorderSide(color: AppColors.line, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.sm,
              borderSide:
                  const BorderSide(color: AppColors.green600, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}