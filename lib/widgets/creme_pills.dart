import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';

/// A round accent action button used at the trailing edge of sheets —
/// the "continue" affordance. [onTap] null = disabled look, still visible.
class RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const RoundActionButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: AppColors.shadow(
              color: AppColors.accent,
              blur: 20,
              y: 6,
              alpha: 0.30,
            ),
          ),
          child: Center(
            child: Icon(icon, size: 24, color: AppColors.onAccent),
          ),
        ),
      ),
    );
  }
}

/// The soft action pill used across the app: a small rounded lozenge with an
/// icon + label. [filled] switches ink-on-paper to accent-on-ink; [onTap]
/// null renders it inert (still styled, just no action).
class SoftPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const SoftPill(
    this.label, {
    super.key,
    this.icon,
    this.filled = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return PressableScale(
      haptic: true,
      onTap: enabled
          ? () {
              onTap!();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: filled ? AppColors.accent : AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(24),
            boxShadow: filled
                ? AppColors.shadow(
                    color: AppColors.accent, blur: 18, y: 5, alpha: 0.26)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: filled ? AppColors.onAccent : AppColors.textPrimary,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: filled ? AppColors.onAccent : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
