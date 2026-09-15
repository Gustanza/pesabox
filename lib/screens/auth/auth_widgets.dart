import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../theme/app_theme.dart';

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
        'P',
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

  const PrimaryButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green600,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.ink400,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const OutlineButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.green600,
          side: const BorderSide(color: AppColors.green600, width: 1.5),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.green600,
          ),
        ),
      ),
    );
  }
}

class ScreenBackButton extends StatelessWidget {
  final bool dark;
  final VoidCallback? onPressed;

  const ScreenBackButton({super.key, this.dark = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? const Color(0x1FFFFFFF) : AppColors.cream,
          border: Border.all(
            color: dark ? const Color(0x33FFFFFF) : AppColors.line,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 16,
          color: dark ? AppColors.white : AppColors.ink900,
        ),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final bool dark;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;

  const AuthHeader({
    super.key,
    this.dark = false,
    this.title,
    this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenBackButton(dark: dark, onPressed: onBack),
        if (title != null || subtitle != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: dark ? AppColors.white : AppColors.ink900,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.ink400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
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

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.requiredField = true,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink700,
            ),
            children: requiredField
                ? [
                    TextSpan(
                      text: ' *',
                      style: GoogleFonts.inter(color: AppColors.danger),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink900),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.ink400,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line, width: 1.5),
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
        Text.rich(
          TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink700,
            ),
            children: requiredField
                ? [
                    TextSpan(
                      text: ' *',
                      style: GoogleFonts.inter(color: AppColors.danger),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
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
          textStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.ink900),
          selectorTextStyle:
              GoogleFonts.inter(fontSize: 14, color: AppColors.ink900),
          inputDecoration: InputDecoration(
            hintText: 'Phone number',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.ink400),
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line, width: 1.5),
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