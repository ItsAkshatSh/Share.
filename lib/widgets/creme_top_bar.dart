import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'creme_icons.dart';

/// The homeScreen top bar: ink "share." wordmark on the left, a bell /
/// avatar / search cluster on the right. [inkColor] lets it sit on both the
/// dark feed and the light paper globe.
class HomeTopBar extends StatelessWidget {
  final bool signedIn;
  final Color inkColor;
  final VoidCallback? onBell;
  final VoidCallback? onSearch;
  final VoidCallback? onSignIn;
  final VoidCallback? onAvatar;

  const HomeTopBar({
    super.key,
    required this.signedIn,
    required this.inkColor,
    this.onBell,
    this.onSearch,
    this.onSignIn,
    this.onAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 14, 4),
      child: Row(
        children: [
          // Wordmark: "share" plus the accent dot.
          Text.rich(
            TextSpan(
              text: 'share',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: inkColor,
              ),
              children: [
                TextSpan(
                  text: '.',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _TopAction(
            onTap: onBell,
            child: AppIcons.bell(size: 21, color: inkColor),
          ),
          const SizedBox(width: 14),
          _TopAction(
            onTap: onAvatar ?? onSignIn,
            child: signedIn
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: inkColor.withValues(alpha: 0.08),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 17,
                      color: inkColor,
                    ),
                  )
                : Icon(
                    Icons.person_outline_rounded,
                    size: 21,
                    color: inkColor,
                  ),
          ),
          const SizedBox(width: 14),
          _TopAction(
            onTap: onSearch,
            child: AppIcons.search(size: 21, color: inkColor),
          ),
        ],
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _TopAction({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: child,
      ),
    );
  }
}
