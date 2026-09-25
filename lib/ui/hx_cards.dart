import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'hx_button.dart';

/// The standard HelaBox surface: white, hairline border, 16px radius.
/// Use it for every card so padding/radius/border stop drifting per screen.
class HxSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadius? radius;
  final Color color;

  const HxSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.x16),
    this.onTap,
    this.radius,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius ?? AppRadius.md,
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return content;
    return Pressable(onTap: onTap, radius: radius, child: content);
  }
}

/// Brand hero card (teal gradient) — the dashboard balance & cycle leaders.
class HxHero extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const HxHero({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(AppSpace.x20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.teal900, AppColors.teal800],
        ),
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Unified stat cell — the same card everywhere (was 14/15/16/17px ×
/// 4 radius/color variants across screens).
class HxStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double valueSize;
  final FontWeight valueWeight;
  final IconData? icon;

  const HxStat({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.ink900,
    this.valueSize = 16,
    this.valueWeight = FontWeight.w700,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return HxSurface(
      padding: const EdgeInsets.all(AppSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.ink400),
                const SizedBox(width: AppSpace.x4),
              ],
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x8),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: valueSize,
              fontWeight: valueWeight,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Key→value pair row inside a details card.
class HxKV extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Widget? trailing;

  const HxKV({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink400,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.x12),
          Flexible(
            child: trailing ??
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Read-only "info strip" inside a card: thin tinted surface, icon + text
/// (e.g. "These rules will apply to your group").
class HxHint extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color background;
  final Color foreground;

  const HxHint({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.background = AppColors.green100,
    this.foreground = AppColors.teal800,
  });

  @override
  Widget build(BuildContext context) {
    return HxSurface(
      padding: const EdgeInsets.all(AppSpace.x12),
      color: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpace.x8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}