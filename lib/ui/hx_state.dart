import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../i18n/i18n.dart';
import '../theme/app_theme.dart';
import 'hx_button.dart';
import 'hx_cards.dart';

/// Premium empty state: icon + title + human message + one clear CTA.
/// Replaces the bare grey sentence that currently fakes as an empty state.
class HxEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool card;

  const HxEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.card = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x24,
        vertical: AppSpace.x32,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green100,
            ),
            child: Icon(icon, size: 26, color: AppColors.teal800),
          ),
          const SizedBox(height: AppSpace.x16),
          Text(
            tr(title),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: AppSpace.x8),
          Text(
            tr(message),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: AppColors.ink600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpace.x20),
            SizedBox(
              width: 200,
              child: HxButton(
                text: actionLabel!,
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );

    if (!card) return content;
    return HxSurface(
      padding: EdgeInsets.zero,
      child: content,
    );
  }
}

/// Skeleton loading block with a soft, calm pulse (no spinner while a whole
/// list is loading — the premium-loading rule).
class HxSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius radius;

  const HxSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = AppRadius.sm,
  });

  @override
  State<HxSkeleton> createState() => _HxSkeletonState();
}

class _HxSkeletonState extends State<HxSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: widget.radius,
        ),
      ),
    );
  }
}

/// Skeleton for a whole list inside one card — [rows] row placeholders with
/// avatar dot + two text lines, identical in shape to a real [HxRow].
class HxSkeletonList extends StatelessWidget {
  final int rows;
  final bool showHeader;

  const HxSkeletonList({super.key, this.rows = 5, this.showHeader = false});

  @override
  Widget build(BuildContext context) {
    return HxSurface(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x4),
      child: Column(
        children: List.generate(rows, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.x16,
              vertical: AppSpace.x12,
            ),
            child: Row(
              children: [
                HxSkeleton(
                  width: 40,
                  height: 40,
                  radius: AppRadius.circular(20),
                ),
                const SizedBox(width: AppSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HxSkeleton(
                        width: i.isEven ? 160 : math.min(200.0, 60.0 + i * 28),
                        height: 12,
                      ),
                      const SizedBox(height: AppSpace.x8),
                      const HxSkeleton(width: 90, height: 10),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.x12),
                const HxSkeleton(width: 56, height: 12),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Two-stat strip skeleton (used while dashboard/group data loads).
class HxSkeletonStats extends StatelessWidget {
  final int count;

  const HxSkeletonStats({super.key, this.count = 2});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: HxSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HxSkeleton(width: 60, height: 10),
                SizedBox(height: AppSpace.x8),
                HxSkeleton(width: 100, height: 16),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}