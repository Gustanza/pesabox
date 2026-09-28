import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../i18n/i18n.dart';
import '../theme/app_theme.dart';
import 'hx_button.dart';

/// What the user picked on the success popup.
enum HxSuccessAction { again, done, details }

/// "Saved!" popup shown after a money record is created: animated check,
/// the amount, the record's details, and a choice to record another (stay),
/// finish (leave) or open the record. Dismissing it counts as [again] —
/// the user stays where they are.
Future<HxSuccessAction> showHxSuccess(
  BuildContext context, {
  required String title,
  required String amount,
  required List<(String, String)> details,
  String againLabel = 'Record another',
  bool showDetails = true,
}) async {
  final picked = await showGeneralDialog<HxSuccessAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'success',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, _) => _HxSuccessDialog(
      title: title,
      amount: amount,
      details: details,
      againLabel: againLabel,
      showDetails: showDetails,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
  return picked ?? HxSuccessAction.again;
}

class _HxSuccessDialog extends StatelessWidget {
  final String title;
  final String amount;
  final List<(String, String)> details;
  final String againLabel;
  final bool showDetails;

  const _HxSuccessDialog({
    required this.title,
    required this.amount,
    required this.details,
    required this.againLabel,
    required this.showDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x24),
        child: Material(
          color: AppColors.white,
          borderRadius: AppRadius.lg,
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.x20,
                      AppSpace.x16,
                      AppSpace.x20,
                      AppSpace.x20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < details.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.line),
                          _row(details[i].$1, details[i].$2),
                        ],
                        const SizedBox(height: AppSpace.x20),
                        HxButton(
                          text: tr(againLabel),
                          icon: Icons.add_rounded,
                          onPressed: () =>
                              Navigator.of(context).pop(HxSuccessAction.again),
                        ),
                        const SizedBox(height: AppSpace.x8),
                        HxButton(
                          text: tr('Done'),
                          variant: HxButtonVariant.secondary,
                          onPressed: () =>
                              Navigator.of(context).pop(HxSuccessAction.done),
                        ),
                        if (showDetails)
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context)
                                    .pop(HxSuccessAction.details),
                            child: Text(
                              tr('View details'),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.teal800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.x20,
        AppSpace.x24,
        AppSpace.x20,
        AppSpace.x20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.teal900, AppColors.teal800],
        ),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 520),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green500,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.25),
                  width: 6,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 36,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.x16),
          Text(
            tr(title),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpace.x8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(label),
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink600),
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
