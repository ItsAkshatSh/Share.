import 'package:flutter/material.dart';

/// The official four-colour Google "G" drawn as paths — used on the
/// white sign-in pill. Sized by [size].
class GoogleGlyph extends StatelessWidget {
  final double size;

  const GoogleGlyph({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    void path(String d, Color color) {
      final glyph = _fromPathData(d);
      if (glyph == null) return;
      canvas.drawPath(glyph, Paint()..color = color);
    }

    path(
      'M23.49 12.27c0-.79-.07-1.54-.19-2.27H12v4.51h6.47a5.54 5.54 0 0 1-2.4 3.58v3h3.86c2.26-2.09 3.56-5.17 3.56-8.82z',
      const Color(0xFF4285F4),
    );
    path(
      'M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.86-3c-1.05.72-2.41 1.16-4.07 1.16-3.13 0-5.78-2.11-6.73-4.96H1.29v3.09A11.99 11.99 0 0 0 12 24z',
      const Color(0xFF34A853),
    );
    path(
      'M5.27 14.29A7.2 7.2 0 0 1 4.89 12c0-.8.14-1.56.38-2.29V6.62H1.29a11.86 11.86 0 0 0 0 10.76l3.98-3.09z',
      const Color(0xFFFBBC05),
    );
    path(
      'M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.31 0 3.26 2.69 1.29 6.62l3.98 3.09C6.22 6.86 8.87 4.75 12 4.75z',
      const Color(0xFFEA4335),
    );

    canvas.restore();
  }

  /// Minimal SVG path-data parser (M, L, C, Z, absolute only) — enough for
  /// the four fixed glyph strings above.
  static Path? _fromPathData(String d) {
    final path = Path();
    var i = 0;
    String? readNumber() {
      while (i < d.length && !_isNumStart(d[i])) {
        i++;
      }
      if (i >= d.length) return null;
      final start = i;
      if (d[i] == '-') i++;
      while (i < d.length && ((_isDigit(d[i])) || d[i] == '.')) {
        i++;
      }
      return d.substring(start, i);
    }

    var command = '';

    while (i < d.length) {
      final ch = d[i];
      if (ch == ' ' || ch == ',') {
        i++;
        continue;
      }
      if (_isCommand(ch)) {
        command = ch;
        i++;
        continue;
      }
      switch (command) {
        case 'M':
          final x = double.tryParse(readNumber() ?? '');
          final y = double.tryParse(readNumber() ?? '');
          if (x == null || y == null) return path..close();
          path.moveTo(x, y);
          command = 'L';
        case 'L':
          final x = double.tryParse(readNumber() ?? '');
          final y = double.tryParse(readNumber() ?? '');
          if (x == null || y == null) return path..close();
          path.lineTo(x, y);
        case 'C':
          final x1 = double.tryParse(readNumber() ?? '');
          final y1 = double.tryParse(readNumber() ?? '');
          final x2 = double.tryParse(readNumber() ?? '');
          final y2 = double.tryParse(readNumber() ?? '');
          final x = double.tryParse(readNumber() ?? '');
          final y = double.tryParse(readNumber() ?? '');
          if (x1 == null ||
              y1 == null ||
              x2 == null ||
              y2 == null ||
              x == null ||
              y == null) {
            return path..close();
          }
          path.cubicTo(x1, y1, x2, y2, x, y);
        case 'A':
          for (var k = 0; k < 7; k++) {
            readNumber();
          }
          final x = double.tryParse(readNumber() ?? '');
          final y = double.tryParse(readNumber() ?? '');
          if (x == null || y == null) return path..close();
          // Approximate arc with a line — good enough at glyph size.
          path.lineTo(x, y);
        case 'Z':
          path.close();
          i++;
        default:
          i++;
      }
    }
    return path;
  }

  static bool _isCommand(String ch) => 'MLCAZVSHQmlcazvshq'.contains(ch);
  static bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
  static bool _isNumStart(String ch) => _isDigit(ch) || ch == '-' || ch == '.';

  @override
  bool shouldRepaint(covariant _GooglePainter oldDelegate) => false;
}
