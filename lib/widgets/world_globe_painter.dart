import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

/// A black-and-white orthographic globe you can actually *use*:
/// - drag to rotate both longitude and latitude (clamped, orbit-style)
/// - pinch to zoom in/out within [minScale, maxScale]; mouse wheel works too
/// - flick gives momentum; the idle spin pauses while you interact
/// - album pins show the share's hero photo in their discs and are tappable
///   with a generous hit area.
class WorldGlobe extends StatefulWidget {
  final List<GlobePin> pins;
  final double size;

  /// Called with the pin the user tapped, if any.
  final ValueChanged<GlobePin>? onPinTap;

  /// The pin that should render as selected (accent rim + bigger halo).
  final GlobePin? selectedPin;

  final double minScale;
  final double maxScale;

  const WorldGlobe({
    super.key,
    required this.pins,
    this.size = 320,
    this.onPinTap,
    this.selectedPin,
    this.minScale = 1.0,
    this.maxScale = 2.2,
  });

  @override
  State<WorldGlobe> createState() => _WorldGlobeState();
}

class _WorldGlobeState extends State<WorldGlobe>
    with TickerProviderStateMixin {
  static List<List<Offset>>? _landRingsCache;

  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 90))
        ..repeat();

  late final AnimationController _momentum = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // Interactive state.
  double _lonOffset = 0; // radians accumulated by dragging
  double _latOffset = 0; // radians accumulated by dragging, clamped ±85°
  double _scale = 1.0;
  double _scaleStart = 1.0;
  double _momentumVelocity = 0;
  Offset? _lastPanPos;
  bool _dragging = false;
  double _latAtMomentumStart = 0;

  static const double _maxTilt = 85 * math.pi / 180;

  Future<List<List<Offset>>> _loadRings() async {
    if (_landRingsCache != null) return _landRingsCache!;
    final raw = await rootBundle.loadString('assets/map/land.json');
    final rings =
        (jsonDecode(raw) as Map<String, dynamic>)['rings'] as List<dynamic>;
    final parsed = <List<Offset>>[
      for (final r in rings)
        [
          for (var i = 0; i + 1 < (r as List<dynamic>).length; i += 2)
            Offset((r[i] as num).toDouble(), (r[i + 1] as num).toDouble()),
        ],
    ];
    _landRingsCache = parsed;
    return parsed;
  }

  @override
  void dispose() {
    _idle.dispose();
    _momentum.dispose();
    super.dispose();
  }

  double get _tilt => _latOffset.clamp(-_maxTilt, _maxTilt);

  void _hitTest(Offset localPos, double dpr) {
    final local = localPos / dpr;
    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size * 0.46 * _scale;
    final sinP = math.sin(_tilt);
    final cosP = math.cos(_tilt);

    for (final pin in widget.pins.reversed) {
      // Same tilted projection the painter draws with.
      final lat = pin.latitude * math.pi / 180;
      final lon = pin.longitude * math.pi / 180 + _lonOffset;
      final cl = math.cos(lat);
      final x1 = cl * math.sin(lon);
      final y1 = -math.sin(lat);
      final z1 = cl * math.cos(lon);
      final y2 = y1 * cosP - z1 * sinP;
      final z2 = y1 * sinP + z1 * cosP;
      if (z2 < 0) continue; // back hemisphere
      final pos = center + Offset(x1, y2) * radius;
      if ((pos - local).distance < 22) {
        widget.onPinTap?.call(pin);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return FutureBuilder<List<List<Offset>>>(
      future: _loadRings(),
      builder: (context, snap) {
        final rings = snap.data ?? const <List<Offset>>[];
        return Listener(
          onPointerSignal: (e) {
            if (e is PointerScrollEvent) {
              setState(() {
                _scale = (_scale - e.scrollDelta.dy / 900)
                    .clamp(widget.minScale, widget.maxScale);
              });
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _hitTest(d.localPosition, dpr),
            // Scale is a superset of pan — dragging rotates, a second
            // finger pinches. Never mix onPan* with onScale*.
            onScaleStart: (d) {
              _momentum.stop();
              _dragging = true;
              _lastPanPos = d.localFocalPoint;
              _scaleStart = _scale;
            },
            onScaleUpdate: (d) {
              if (d.pointerCount > 1) {
                // Pinch -> zoom.
                setState(() {
                  _scale = (_scaleStart * d.scale)
                      .clamp(widget.minScale, widget.maxScale);
                });
                return;
              }
              // Single pointer -> rotate.
              final delta =
                  d.localFocalPoint - (_lastPanPos ?? d.localFocalPoint);
              _lastPanPos = d.localFocalPoint;
              setState(() {
                _lonOffset += delta.dx / (widget.size * 0.46 * _scale);
                _latOffset = (_latOffset - delta.dy / (widget.size * 0.46 * _scale))
                    .clamp(-_maxTilt, _maxTilt);
              });
            },
            onScaleEnd: (d) {
              _dragging = false;
              _latAtMomentumStart = _latOffset;
              _momentumVelocity =
                  -d.velocity.pixelsPerSecond.dx / (widget.size * 0.46 * _scale);
              _momentum.forward(from: 0);
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([_idle, _momentum]),
              builder: (context, _) {
                // Momentum decay: eased fraction of the flick velocity.
                final t = Curves.decelerate.transform(
                  _momentum.isAnimating ? _momentum.value : 0,
                );
                final momentumLon = _momentum.isAnimating
                    ? _momentumVelocity * (1 - t)
                    : 0.0;

                // Idle spin only turns while the user isn't touching.
                final idleLon = _dragging || _momentum.isAnimating
                    ? 0.0
                    : _idle.value * 2 * math.pi;

                return CustomPaint(
                  size: Size.square(widget.size),
                  painter: _GlobePainter(
                    rings: rings,
                    pins: widget.pins,
                    selectedPin: widget.selectedPin,
                    rotation: _lonOffset + momentumLon + idleLon,
                    latTilt: _dragging || _momentum.isAnimating
                        ? _tilt
                        : _latAtMomentumStart * 0 + _tilt,
                    scale: _scale,
                    dpr: dpr,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class GlobePin {
  final String hangoutId;
  final String title;
  final double latitude;
  final double longitude;
  final Color color;

  /// Optional hero photo URL (local file path or network) shown inside the
  /// pin's disc, cover-cropped to a circle.
  final String? photoUrl;

  const GlobePin({
    required this.hangoutId,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.color,
    this.photoUrl,
  });
}

class _GlobePainter extends CustomPainter {
  final List<List<Offset>> rings;
  final List<GlobePin> pins;
  final GlobePin? selectedPin;
  final double rotation; // radians, west-positive
  final double latTilt; // radians — tilt of the observed pole
  final double scale;
  final double dpr;

  _GlobePainter({
    required this.rings,
    required this.pins,
    required this.selectedPin,
    required this.rotation,
    required this.latTilt,
    required this.scale,
    required this.dpr,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.46 * scale;

    // Ocean disc.
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.surface,
    );

    // Graticule — projected latitude/longitude arcs give the sphere depth.
    // Latitude rings draw as true ellipse arcs; meridians as ellipse halves.
    final grid = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void strokePath(Path p) => canvas.drawPath(p, grid);

    final lambda = rotation;
    final sinP = math.sin(latTilt);
    final cosP = math.cos(latTilt);

    // Tilted orthographic projection: longitude spin, then tilt rotate.
    (double, double, double)? project3(double latDeg, double lonDeg) {
      final lat = latDeg * math.pi / 180;
      final lon = lonDeg * math.pi / 180 + lambda;
      final cl = math.cos(lat);
      final x1 = cl * math.sin(lon);
      final y1 = -math.sin(lat);
      final z1 = cl * math.cos(lon);
      final y2 = y1 * cosP - z1 * sinP;
      final z2 = y1 * sinP + z1 * cosP;
      if (z2 < 0) return null; // far side
      return (x1, y2, z2);
    }

    // Latitude circles every 30°, sampled through the same projection as
    // land and pins so the whole sphere reads as one coherent surface.
    Path sampledArc(List<(double, double, double)> pts) {
      final path = Path();
      bool penDown = false;
      for (final (x, y, _) in pts) {
        final screen = center + Offset(x, y) * radius;
        if (!penDown) {
          path.moveTo(screen.dx, screen.dy);
          penDown = true;
        } else {
          path.lineTo(screen.dx, screen.dy);
        }
      }
      return path;
    }

    for (final latDeg in [-60, -30, 0, 30, 60]) {
      final pts = <(double, double, double)>[];
      for (double lonDeg = -180; lonDeg < 180; lonDeg += 4) {
        final r = project3(latDeg.toDouble(), lonDeg);
        if (r != null) pts.add(r);
      }
      if (pts.length > 1) strokePath(sampledArc(pts));
    }
    // Meridians every 30°.
    for (double lonDeg = -180; lonDeg < 180; lonDeg += 30) {
      final pts = <(double, double, double)>[];
      for (double latDeg = -90; latDeg <= 90; latDeg += 4) {
        final r = project3(latDeg, lonDeg);
        if (r != null) pts.add(r);
      }
      if (pts.length > 1) strokePath(sampledArc(pts));
    }

    // Land ink.
    final ink = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    void projectPath(Path path, List<Offset> pts) {
      path.reset();
      bool penDown = false;
      for (final p in pts) {
        final r = project3(p.dx, p.dy);
        if (r == null) {
          penDown = false;
          continue;
        }
        final (x, y, _) = r;
        final screen = center + Offset(x, y) * radius;
        if (!penDown) {
          path.moveTo(screen.dx, screen.dy);
          penDown = true;
        } else {
          path.lineTo(screen.dx, screen.dy);
        }
      }
    }

    final path = Path();
    for (final ring in rings) {
      projectPath(path, ring);
      canvas.drawPath(path, ink);
    }

    // Limb — the sphere's edge.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Pins — photo discs for each share, with a selected halo.
    for (final pin in pins) {
      final p3 = project3(pin.latitude, pin.longitude);
      if (p3 == null) continue;
      final (x, y, _) = p3;
      final pos = center + Offset(x, y) * radius;
      final isSelected = selectedPin?.hangoutId == pin.hangoutId;
      final r = isSelected ? 15.0 : 11.0;

      // Halo.
      canvas.drawCircle(
        pos,
        r + (isSelected ? 6 : 3),
        Paint()
          ..color = pin.color.withValues(alpha: isSelected ? 0.55 : 0.38)
          ..style = PaintingStyle.fill,
      );

      // Photo disc — clip a circle, fill with the album hero when decoded,
      // else the accent color.
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: pos, radius: r)),
      );
      final img = pin.photoUrl == null ? null : pinImageCache[pin.photoUrl];
      if (img != null) {
        final side = math.min(img.width, img.height).toDouble();
        final srcSq = Rect.fromCenter(
          center: Offset(img.width / 2, img.height / 2),
          width: side,
          height: side,
        );
        canvas.drawImageRect(
          img,
          srcSq,
          Rect.fromCircle(center: pos, radius: r),
          Paint(),
        );
      } else {
        canvas.drawCircle(pos, r, Paint()..color = pin.color);
      }
      canvas.restore();

      // Rim.
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = isSelected ? AppColors.accent : AppColors.textPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.2 : 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(_GlobePainter old) =>
      old.rotation != rotation ||
      old.latTilt != latTilt ||
      old.scale != scale ||
      old.rings != rings ||
      old.pins != pins ||
      old.selectedPin != selectedPin ||
      old.dpr != dpr;
}

/// Decoded pin photos, keyed by URL/path. Loading is async; the screen calls
/// back into a setState as each completes so the disc fills in.
final Map<String, ui.Image> pinImageCache = {};

/// Decodes [url] (asset / file / https) into the paint-time image cache and
/// fires [onLoaded] once it's ready.
Future<void> precachePinImage(String? url, VoidCallback onLoaded) async {
  if (url == null || url.isEmpty || pinImageCache.containsKey(url)) return;
  try {
    Uint8List? data;
    if (url.startsWith('assets/')) {
      data = (await rootBundle.load(url)).buffer.asUint8List();
    } else if (url.startsWith('http')) {
      final client = HttpClient();
      final resp =
          await client.getUrl(Uri.parse(url)).then((req) => req.close());
      final builder = BytesBuilder();
      await for (final chunk in resp) {
        builder.add(chunk);
      }
      data = builder.takeBytes();
      client.close();
    } else {
      final file = File(url);
      if (file.existsSync()) data = await file.readAsBytes();
    }
    if (data == null) return;
    final codec = await ui.instantiateImageCodec(
      data,
      targetWidth: 96,
      targetHeight: 96,
    );
    final frame = await codec.getNextFrame();
    pinImageCache[url] = frame.image;
    onLoaded();
  } catch (_) {
    // A missing photo just renders the accent disc instead.
  }
}
