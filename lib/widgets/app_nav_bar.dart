import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'creme_icons.dart';

/// The bottom navigation: a floating paper pill over a deep indigo underlay,
/// with chunky squircle tiles that lean like arcade buttons.
///
/// Tapping a tile squashes it inward (scale-down on press, spring back on
/// release) — the active tile is filled accent indigo with white ink, and a
/// little ink dot hops beneath it. The ＋ tile is a bigger round accent
/// button with the tiny white badge, like the reference.
enum NavItem { home, world, saved, settings }

class AppNavBar extends StatelessWidget {
  final NavItem current;
  final ValueChanged<NavItem> onChanged;
  final int badgeCount;

  const AppNavBar({
    super.key,
    required this.current,
    required this.onChanged,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomInset),
      // Deep indigo underlay peeking around the paper pill. (Margin must
      // stay non-negative, so the 2px peek below is done with translate.)
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, 2),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accentDeep,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: AppColors.shadow(blur: 18, y: 7, alpha: 0.14),
            ),
            child: Row(
              children: [
                _NavTile(
                  item: NavItem.home,
                  current: current,
                  onChanged: onChanged,
                ),
                _NavTile(
                  item: NavItem.world,
                  current: current,
                  onChanged: onChanged,
                ),
                _NavTile(
                  item: NavItem.saved,
                  current: current,
                  onChanged: onChanged,
                  badgeCount: badgeCount,
                ),
                _NavTile(
                  item: NavItem.settings,
                  current: current,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final NavItem item;
  final NavItem current;
  final ValueChanged<NavItem> onChanged;
  final int badgeCount;

  const _NavTile({
    required this.item,
    required this.current,
    required this.onChanged,
    this.badgeCount = 0,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _squash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _scale =
      Tween(begin: 1.0, end: 0.86).animate(_squash);

  @override
  void dispose() {
    _squash.dispose();
    super.dispose();
  }

  bool get _active => widget.current == widget.item;

  static String _labelFor(NavItem item) => switch (item) {
        NavItem.home => 'home',
        NavItem.world => 'world',
        NavItem.saved => 'saved',
        NavItem.settings => 'you',
      };

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final active = _active;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _squash.forward(),
        onTapCancel: () => _squash.reverse(),
        onTap: () {
          _squash.reverse();
          widget.onChanged(item);
        },
        child: AnimatedBuilder(
          animation: _squash,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(child: _glyphFor(item, active)),
                    if (widget.badgeCount > 0 && item == NavItem.saved)
                      Positioned(
                        top: -3,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4.5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.surface, width: 1.5),
                          ),
                          child: Text(
                            widget.badgeCount > 9
                                ? '9+'
                                : '${widget.badgeCount}',
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              // The hopping ink dot — a fun little active marker.
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                width: active ? 4 : 0,
                height: active ? 4 : 0,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                _labelFor(item),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: active ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glyphFor(NavItem item, bool active) {
    final    color = active ? AppColors.onAccent : AppColors.textPrimary;
    return switch (item) {
      NavItem.home => AppIcons.home(size: 19, color: color),
      NavItem.world => AppIcons.globe(size: 19, color: color),
      NavItem.saved => AppIcons.heart(size: 19, color: color),
      NavItem.settings => AppIcons.browseGrid(size: 19, color: color),
    };
  }
}
