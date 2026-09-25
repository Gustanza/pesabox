import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'hx_button.dart';

/// Deterministic initials avatar. Hues come from the brand tokens (teal,
/// gold, cream, green) — never stray purple/blue.
class HxAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final bool square;

  const HxAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.square = false,
  });

  static const _toneBg = [
    AppColors.green100,
    AppColors.teal100,
    AppColors.gold100,
    AppColors.cream,
    AppColors.danger100,
  ];
  static const _toneFg = [
    AppColors.teal800,
    AppColors.teal900,
    AppColors.teal900,
    AppColors.teal800,
    AppColors.danger,
  ];

  @override
  Widget build(BuildContext context) {
    final idx = (initials.hashCode % _toneBg.length).abs();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _toneBg[idx],
        borderRadius: square ? AppRadius.sm : null,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(size * 0.14),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            initials,
            maxLines: 1,
            style: GoogleFonts.inter(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
              color: _toneFg[idx],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tinted status pill. [tone] picks the brand-safe pair; never raw hex.
enum HxPillTone { neutral, success, warning, danger, info }

class HxPill extends StatelessWidget {
  final String text;
  final HxPillTone tone;
  final bool dot;

  const HxPill({
    super.key,
    required this.text,
    this.tone = HxPillTone.neutral,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      HxPillTone.neutral => (AppColors.cream, AppColors.ink600),
      HxPillTone.success => (AppColors.green100, AppColors.teal800),
      HxPillTone.warning => (AppColors.gold100, AppColors.teal900),
      HxPillTone.danger => (AppColors.danger100, AppColors.danger),
      HxPillTone.info => (AppColors.teal100, AppColors.teal900),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// The standard tappable list row: avatar + title + subtitle + trailing
/// (pill, money, chevron…). One component replaces the 4 hand-rolled row
/// templates across member/meeting/loan/fine/transaction lists.
class HxRow extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? titleTrailing;

  const HxRow({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      radius: const BorderRadius.all(Radius.circular(0)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x16,
            vertical: AppSpace.x12,
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AppSpace.x12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title!,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink900,
                              ),
                            ),
                          ),
                          if (titleTrailing != null) ...[
                            const SizedBox(width: AppSpace.x8),
                            titleTrailing!,
                          ],
                        ],
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.ink400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpace.x12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu-style row (icon chip + label + optional caption + chevron) — the
/// Group Info / Reports / Profile menu walls.
class HxMenuRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool addDivider;

  const HxMenuRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.onTap,
    this.addDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final row = HxRow(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.sm,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: title,
      subtitle: subtitle,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 22,
        color: AppColors.ink400,
      ),
    );
    if (!addDivider) return row;
    return Column(
      children: [
        row,
        const Divider(height: 1, indent: 68),
      ],
    );
  }
}

/// The screen "See all →"/link affordance — quiet link in brand dark green.
class HxLink extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const HxLink({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.teal900,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.teal900,
        ),
      ),
    );
  }
}