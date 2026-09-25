import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../i18n/i18n.dart';
import '../theme/app_theme.dart';

/// The one premium action button. Use [variant] to express hierarchy —
/// only ONE primary per screen.
enum HxButtonVariant { primary, secondary, quiet, destructive }

/// Full-width action button with the app's micro-interaction language:
/// label → loading spinner → success check. Pick [variant] by hierarchy.
class HxButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final HxButtonVariant variant;
  final bool loading;
  final bool success;
  final IconData? icon;
  final double height;

  const HxButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = HxButtonVariant.primary,
    this.loading = false,
    this.success = false,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = switch (variant) {
      HxButtonVariant.primary => _elevated(enabled),
      HxButtonVariant.destructive => _elevated(enabled, danger: true),
      HxButtonVariant.secondary => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          child: _content(AppColors.teal900),
        ),
      HxButtonVariant.quiet => TextButton(
          onPressed: enabled ? onPressed : null,
          child: _content(AppColors.teal900),
        ),
    };

    return SizedBox(
      height: height,
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(
          key: ValueKey('$variant-$loading-$success'),
          child: child,
        ),
      ),
    );
  }

  Widget _elevated(bool enabled, {bool danger = false}) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            danger ? AppColors.danger : AppColors.green600,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      child: _content(AppColors.white),
    );
  }

  Widget _content(Color color) {
    if (loading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
    if (success) {
      return Icon(Icons.check_rounded, size: 20, color: color);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpace.x8),
        ],
        Flexible(
          child: Text(
            tr(text),
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small circular icon control for headers (pencil on a detail screen etc).
class HxIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color color;
  final double size;

  const HxIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color = AppColors.teal900,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.cream,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.5, color: color),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Wraps any surface (cards, rows, tiles) so it presses-and-lifts on tap —
/// the app's signature "alive before you finish tapping" micro-interaction.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? radius;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.radius,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius ?? AppRadius.md;
    return Listener(
      onPointerDown: widget.onTap == null ? null : (_) => _set(true),
      onPointerUp: widget.onTap == null ? null : (_) => _set(false),
      onPointerCancel: widget.onTap == null ? null : (_) => _set(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: _pressed ? AppShadow.low : null,
            ),
            child: ClipRRect(borderRadius: radius, child: widget.child),
          ),
        ),
      ),
    );
  }
}