import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A white paper card — the container most screens are built from. Soft
/// shadow, generous radius, optional external margin.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const Panel({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 14),
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.shadow(blur: 20, y: 8, alpha: 0.10),
      ),
      child: child,
    );
  }
}

/// Tiny spaced-out eyebrow label above a Panel — "APPEARANCE", "GUESTS"…
/// Optional right-aligned trailing widget (a count, a link).
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
