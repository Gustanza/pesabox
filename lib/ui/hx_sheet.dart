import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../i18n/i18n.dart';
import '../theme/app_theme.dart';

/// Open a standard HelaBox bottom sheet (white, 24px top radius, drag
/// handle) — replaces the cream-radius-20 hand-built sheets.
Future<T?> showHxSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext) builder,
  bool scrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    useSafeArea: true,
    backgroundColor: AppColors.white,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.topLg),
    builder: builder,
  );
}

/// Segmented filter control (Meetings/Transaction lists). One control across
/// the app instead of two competing implementations.
class HxSegment extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final Color background;
  final Color foreground;

  const HxSegment({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.background = AppColors.white,
    this.foreground = AppColors.green600,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.x4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
                decoration: BoxDecoration(
                  color: active ? foreground : Colors.transparent,
                  borderRadius: AppRadius.circular(8),
                ),
                child: Text(
                  tr(options[i]),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active
                        ? AppColors.white
                        : AppColors.ink600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A selectable chip used in report/export filters.
class HxChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const HxChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.teal800 : AppColors.ink600;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x12,
          vertical: AppSpace.x8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.green100 : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.green100 : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              tr(label),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}