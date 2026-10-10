import 'package:flutter/material.dart';

/// Motion tokens following Apple's *Designing Fluid Interfaces* guidance:
/// critically damped by default, a little bounce only when a gesture carried
/// momentum, and a reduced-motion path that cross-fades instead of moving.
class AppMotion {
  AppMotion._();

  /// Response time for most UI (Apple: 0.3–0.4s). Not a fixed duration —
  /// a spring's settle time emerges from its parameters.
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);

  /// Sheets use a slightly longer ease that eases out hard then settles.
  static const Curve sheetCurve = Curves.easeOutCubic;
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Animate only when the user hasn't asked for reduced motion.
  /// Under `prefers-reduced-motion` we swap movement for a short cross-fade.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration preferred) =>
      reduceMotion(context) ? fast : preferred;

  /// A scale for \"press\" feedback. Returns 1.0 when motion is reduced so the
  /// control still gives a color/opacity cue without moving.
  static double pressScale(BuildContext context, {double scale = 0.97}) =>
      reduceMotion(context) ? 1.0 : scale;
}

/// Wraps a tappable child with instant press-down feedback.
///
/// Per Apple's response rule, the highlight fires on pointer-*down* (not on
/// release), so the interface never feels dead. The scale animates with a
/// short, non-overshooting curve, and collapses to an opacity change when the
/// user prefers reduced motion.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.haptic = false,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    final target = _pressed && !reduce ? widget.pressedScale : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null && widget.onLongPress == null
          ? null
          : (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) Feedback.forTap(context);
              widget.onTap!.call();
            },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: target,
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: AppMotion.standardCurve,
        child: AnimatedOpacity(
          opacity: _pressed && reduce ? 0.72 : 1.0,
          duration: AppMotion.duration(context, AppMotion.fast),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Slides a widget up into place on first build, like a sheet materializing.
/// Cross-fades instead when reduced motion is on.
class EnterTransition extends StatefulWidget {
  final Widget child;
  final Duration delay;

  /// Starting offset as a fraction of the child's height (e.g. 0.06 = 6%).
  final double offset;

  const EnterTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 0.06,
  });

  @override
  State<EnterTransition> createState() => _EnterTransitionState();
}

class _EnterTransitionState extends State<EnterTransition> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _shown = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    return AnimatedSlide(
      offset: _shown || reduce ? Offset.zero : Offset(0, widget.offset),
      duration: AppMotion.duration(context, AppMotion.standard),
      curve: AppMotion.standardCurve,
      child: AnimatedOpacity(
        opacity: _shown ? 1.0 : 0.0,
        duration: AppMotion.duration(context, AppMotion.standard),
        child: widget.child,
      ),
    );
  }
}
