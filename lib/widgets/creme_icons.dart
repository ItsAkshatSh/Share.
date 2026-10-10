import 'package:flutter/material.dart';

/// the app's dock and action glyphs are chunky, rounded-geometric marks that
/// read as friendly hardware buttons rather than hairline iOS icons. Flutter's
/// Material icons don't match that weight, so the app draws its own.
class AppIcons {
  AppIcons._();

  /// Four rounded squares with one dot — the "browse all" glyph.
  static Widget browseGrid({double size = 22, Color? color}) {
    return _Glyph(size: size, painter: (p) => _browse(p, color ?? const Color(0xFF16141C)));
  }

  /// The sparkle + fork glyph used in the floating action button.
  static Widget sparkles({double size = 22, Color? color}) {
    return _Glyph(size: size, painter: (p) => _sparkles(p, color ?? const Color(0xFF16141C)));
  }

  /// Chunky cart silhouette for the dock.
  static Widget cart({double size = 22, Color? color}) {
    return _Glyph(size: size, painter: (p) => _cart(p, color ?? const Color(0xFF16141C)));
  }

  /// Rounded house for the dock's first slot.
  static Widget home({double size = 24, Color? color}) {
    return _Glyph(size: size, painter: (p) => _home(p, color ?? const Color(0xFF16141C)));
  }

  /// Globe (meridian + parallels) for the "your world" dock slot.
  static Widget globe({double size = 24, Color? color}) {
    return _Glyph(size: size, painter: (p) => _globe(p, color ?? const Color(0xFF16141C)));
  }

  /// Heart outline for save/like affordances.
  static Widget heart({double size = 22, Color? color}) {
    return _Glyph(size: size, painter: (p) => _heart(p, color ?? const Color(0xFF16141C), false));
  }

  static Widget heartFilled({double size = 22, Color? color}) {
    return _Glyph(size: size, painter: (p) => _heart(p, color ?? const Color(0xFF16141C), true));
  }

  /// Bell for notifications.
  static Widget bell({double size = 22, Color? color}) {
    return _Glyph(size: size, painter: (p) => _bell(p, color ?? const Color(0xFF16141C)));
  }

  /// Magnifying glass.
  static Widget search({double size = 22, Color? color}) {
    return _Glyph(size: size, painter: (p) => _search(p, color ?? const Color(0xFF16141C)));
  }

  static void _paintStroke(
    Canvas canvas,
    Path path,
    Color? color, {
    double stroke = 2.0,
  }) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color ?? const Color(0xFF16141C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static void _browse(Canvas canvas, Color? c) {
    final white = c ?? const Color(0xFF16141C);
    void sq(double l, double t, double s) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(l, t, s, s),
        const Radius.circular(3),
      );
      canvas.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = white);
    }

    sq(1, 1, 8);
    sq(15, 1, 8);
    sq(1, 15, 8);
    // Missing fourth square replaced by a filled dot.
    canvas.drawCircle(const Offset(19, 19), 3, Paint()..color = white);
  }

  static void _sparkles(Canvas canvas, Color? c) {
    final white = c ?? const Color(0xFF16141C);
    Path big() {
      return Path()
        ..moveTo(12, 2)
        ..cubicTo(12.7, 6.5, 13.5, 8.5, 16, 10)
        ..cubicTo(13.5, 11.5, 12.7, 13.5, 12, 18)
        ..cubicTo(11.3, 13.5, 10.5, 11.5, 8, 10)
        ..cubicTo(10.5, 8.5, 11.3, 6.5, 12, 2)
        ..close();
    }

    Path small1() {
      return Path()
        ..moveTo(19.5, 13)
        ..cubicTo(19.8, 15, 20.2, 15.7, 21.5, 16.5)
        ..cubicTo(20.2, 17.3, 19.8, 18, 19.5, 20)
        ..cubicTo(19.2, 18, 18.8, 17.3, 17.5, 16.5)
        ..cubicTo(18.8, 15.7, 19.2, 15, 19.5, 13)
        ..close();
    }

    Path small2() {
      return Path()
        ..moveTo(5.5, 15)
        ..cubicTo(5.8, 16.6, 6.2, 17.2, 7.3, 17.9)
        ..cubicTo(6.2, 18.6, 5.8, 19.2, 5.5, 20.8)
        ..cubicTo(5.2, 19.2, 4.8, 18.6, 3.7, 17.9)
        ..cubicTo(4.8, 17.2, 5.2, 16.6, 5.5, 15)
        ..close();
    }

    canvas.drawPath(big(), Paint()..color = white);
    canvas.drawPath(small1(), Paint()..color = white);
    canvas.drawPath(small2(), Paint()..color = white);
  }

  static void _cart(Canvas canvas, Color? c) {
    final white = c ?? const Color(0xFF16141C);
    _paintStroke(canvas, Path()
      ..moveTo(2, 4)
      ..lineTo(5, 4)
      ..lineTo(7.5, 15)
      ..lineTo(18.5, 15)
      ..lineTo(21, 7), white, stroke: 2);
    _paintStroke(canvas, Path()
      ..moveTo(6.2, 7)
      ..lineTo(20, 7), white, stroke: 2);
    canvas.drawCircle(const Offset(9, 19.5), 1.9, Paint()..color = white);
    canvas.drawCircle(const Offset(17, 19.5), 1.9, Paint()..color = white);
  }

  static void _home(Canvas canvas, Color? c) {
    final white = c ?? const Color(0xFF16141C);
    _paintStroke(canvas, Path()
      ..moveTo(3, 11)
      ..lineTo(12, 3)
      ..lineTo(21, 11)
      ..lineTo(21, 20)
      ..quadraticBezierTo(21, 21, 20, 21)
      ..lineTo(4, 21)
      ..quadraticBezierTo(3, 21, 3, 20)
      ..close(), white, stroke: 2.2);
    _paintStroke(canvas, Path()
      ..moveTo(9.5, 21)
      ..lineTo(9.5, 15)
      ..lineTo(14.5, 15)
      ..lineTo(14.5, 21), white, stroke: 2);
  }

  static void _globe(Canvas canvas, Color? c) {
    final white = c ?? const Color(0xFF16141C);
    // Outer circle.
    canvas.drawCircle(
      const Offset(12, 12),
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = white,
    );
    // Vertical meridian (ellipse) through the center.
    _paintStroke(canvas, Path()
      ..moveTo(12, 3)
      ..cubicTo(16.5, 6, 16.5, 18, 12, 21)
      ..cubicTo(7.5, 18, 7.5, 6, 12, 3)
      ..close(), white, stroke: 1.7);
    // Horizontal equator.
    _paintStroke(canvas, Path()
      ..moveTo(3, 12)
      ..lineTo(21, 12), white, stroke: 1.7);
    // Two latitude arcs above/below the equator.
    _paintStroke(canvas, Path()
      ..moveTo(4.2, 8)
      ..cubicTo(8, 9.6, 16, 9.6, 19.8, 8), white, stroke: 1.6);
    _paintStroke(canvas, Path()
      ..moveTo(4.2, 16)
      ..cubicTo(8, 14.4, 16, 14.4, 19.8, 16), white, stroke: 1.6);
  }

  static void _heart(Canvas canvas, Color? c, bool filled) {
    final white = c ?? const Color(0xFF16141C);
    final path = Path()
      ..moveTo(12, 20.5)
      ..cubicTo(11.2, 20.5, 4, 15.5, 4, 9.8)
      ..cubicTo(4, 6.5, 6.6, 4.5, 9, 4.5)
      ..cubicTo(10.3, 4.5, 11.4, 5.2, 12, 6.2)
      ..cubicTo(12.6, 5.2, 13.7, 4.5, 15, 4.5)
      ..cubicTo(17.4, 4.5, 20, 6.5, 20, 9.8)
      ..cubicTo(20, 15.5, 12.8, 20.5, 12, 20.5)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = white
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static void _bell(Canvas canvas, Color? c) {
    final white = c ?? const Color(0xFF16141C);
    final path = Path()
      ..moveTo(5, 18)
      ..lineTo(19, 18)
      ..cubicTo(17.2, 16.5, 16.5, 14.5, 16.5, 11)
      ..cubicTo(16.5, 7.5, 14.6, 4.5, 12, 4.5)
      ..cubicTo(9.4, 4.5, 7.5, 7.5, 7.5, 11)
      ..cubicTo(7.5, 14.5, 6.8, 16.5, 5, 18)
      ..close();
    _paintStroke(canvas, path, white, stroke: 2);
    canvas.drawCircle(const Offset(12, 21), 1.4, Paint()..color = white);
  }

  static void _search(Canvas canvas, Color? c) {
    final white = c ?? const Color(0xFF16141C);
    canvas.drawCircle(const Offset(10.5, 10.5), 6.5,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = white);
    _paintStroke(canvas, Path()
      ..moveTo(15.5, 15.5)
      ..lineTo(21, 21), white, stroke: 2.2);
  }
}

class _Glyph extends StatelessWidget {
  final double size;
  final void Function(Canvas canvas) painter;

  const _Glyph({required this.size, required this.painter});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _Delegate(painter)),
    );
  }
}

class _Delegate extends CustomPainter {
  final void Function(Canvas canvas) painter;

  _Delegate(this.painter);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Design space is 24x24, scaled to the requested size.
    canvas.scale(size.width / 24, size.height / 24);
    painter(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Delegate oldDelegate) => false;
}
