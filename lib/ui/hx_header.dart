import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../i18n/i18n.dart';
import '../theme/app_theme.dart';

// Widgets built from nullable strings don't map onto Dart's null-aware
// collection elements, so the per-file lint is disabled deliberately.
// ignore_for_file: use_null_aware_elements

/// The circular back control used across HelaBox sub-screens.
class HxBackButton extends StatelessWidget {
  final bool dark;
  final VoidCallback? onPressed;

  const HxBackButton({super.key, this.dark = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? AppColors.white.withValues(alpha: 0.12) : AppColors.white,
          border: Border.all(
            color: dark
                ? AppColors.white.withValues(alpha: 0.2)
                : AppColors.line,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: dark ? AppColors.white : AppColors.ink900,
        ),
      ),
    );
  }
}

/// The single standard sub-screen header: back, title, optional subtitle and
/// optional trailing actions. Use **everywhere** a back context exists so
/// titles, spacing and type never drift again (was 17/18 px × 700/800 mixed).
class HxHeader extends StatelessWidget {
  final bool dark;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const HxHeader({
    super.key,
    this.dark = false,
    this.title,
    this.subtitle,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HxBackButton(dark: dark, onPressed: onBack),
        if (title != null || subtitle != null) ...[
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    tr(title!),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: dark ? AppColors.white : AppColors.ink900,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpace.x2),
                  Text(
                    tr(subtitle!),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: dark
                          ? AppColors.white.withValues(alpha: 0.7)
                          : AppColors.ink400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (actions != null) ...actions!,
      ],
    );
  }
}

/// Standard page title block for root tabs (no back button) — e.g. the
/// Meetings and Activity screens that live inside the bottom nav.
class HxPageTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const HxPageTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            tr(title),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Section heading inside a scrollable screen (e.g. "Quick actions",
/// "Recent activity"). One size, one weight, one color.
class HxSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const HxSectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr(title),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink900,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}