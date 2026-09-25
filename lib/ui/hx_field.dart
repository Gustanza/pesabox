import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../i18n/i18n.dart';
import '../theme/app_theme.dart';

/// Field label with the required asterisk — the same everywhere (was a
/// copy-pasted 12.5px block in five form files).
class HxFieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const HxFieldLabel({super.key, required this.text, this.required = true});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: tr(text),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.ink700,
        ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.inter(color: AppColors.danger),
                ),
              ]
            : null,
      ),
    );
  }
}

/// Standard text field. Decoration comes from [InputDecorationTheme] so every
/// input in the app inherits the same radius/fill/focus treatment.
class HxField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final bool required;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? errorText;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;

  const HxField({
    super.key,
    required this.label,
    this.hint = '',
    this.obscure = false,
    this.required = true,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.onChanged,
    this.errorText,
    this.maxLines,
    this.textInputAction,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HxFieldLabel(text: label, required: required),
        const SizedBox(height: AppSpace.x8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          maxLines: maxLines ?? 1,
          textInputAction: textInputAction,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink900),
          decoration: InputDecoration(
            hintText: hint.isEmpty ? null : hint,
            errorText: errorText,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}