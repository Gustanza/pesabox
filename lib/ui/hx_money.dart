import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// The single money/text display convention.
///
/// - [signed]: pass [positive]/[negative] to render money with the app's ONE
///   semantic color rule — positive in brand-dark teal, negative in danger
///   red. Fintech truth: a -900,000 must never look the same as a balance.
/// - [neutral] (null sign): plain ink900 number/balance.
///
/// Font: Inter 700. Inline amount in a list row uses [size] 14; hero/stat
/// values use a larger [size].
class HxMoney extends StatelessWidget {
  final String text;
  final bool? positive;
  final double fontSize;
  final FontWeight weight;
  final Color? color;
  final TextAlign? align;

  const HxMoney({
    super.key,
    required this.text,
    this.positive,
    this.fontSize = 14,
    this.weight = FontWeight.w700,
    this.color,
    this.align,
  });

  /// A signed, coloured amount. [signed] is already prefixed with +/- if you
  /// want it, or pass [autoSign] to prefix it yourself.
  factory HxMoney.signed({
    required String text,
    required bool positive,
    double? fontSize,
    FontWeight weight = FontWeight.w700,
    bool autoSign = false,
  }) {
    return HxMoney(
      text: autoSign ? (positive ? '+$text' : '-$text') : text,
      positive: positive,
      fontSize: fontSize ?? 14,
      weight: weight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color effective = color ??
        (positive == null
            ? AppColors.ink900
            : positive!
                ? AppColors.positive
                : AppColors.negative);
    return Text(
      text.isEmpty ? '–' : text,
      textAlign: align,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        color: effective,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Small caption under a money value (e.g. "Savings", "Outstanding").
class HxMoneyLabel extends StatelessWidget {
  final String text;
  final Color color;

  const HxMoneyLabel({
    super.key,
    required this.text,
    this.color = AppColors.ink400,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}