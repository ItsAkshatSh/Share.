// Generates assets/map/land.json from world-atlas land-110m TopoJSON.
//
// Run: dart run tool/gen_land_json.dart <path-to-land-110m.json>
//
// Output format: {"rings": [[lon,lat,lon,lat,...], ...]} — flat doubles,
// lon/lat degrees, already absolute (delta-decoded) and simplified.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/gen_land_json.dart <land-110m.json>');
    exit(2);
  }

  final topo =
      jsonDecode(File(args.first).readAsStringSync()) as Map<String, dynamic>;
  final transform = topo['transform'] as Map<String, dynamic>;
  final sx = (transform['scale'] as List)[0] as num;
  final sy = (transform['scale'] as List)[1] as num;
  final tx = (transform['translate'] as List)[0] as num;
  final ty = (transform['translate'] as List)[1] as num;

  // Decode every arc into absolute lon/lat points.
  final rawArcs = topo['arcs'] as List<dynamic>;
  final arcs = <List<List<double>>>[];
  for (final arc in rawArcs) {
    double x = 0, y = 0;
    final pts = <List<double>>[];
    for (final d in (arc as List<dynamic>)) {
      x += (d as List<dynamic>)[0] as num;
      y += d[1] as num;
      pts.add([x * sx + tx, y * sy + ty]);
    }
    arcs.add(pts);
  }

  List<List<double>> ringFromIndices(List<dynamic> indices) {
    final ring = <List<double>>[];
    for (final idxDyn in indices) {
      int idx = idxDyn as int;
      final reversed = idx < 0;
      if (reversed) idx = -idx - 1;
      final arc = arcs[idx];
      final start = ring.isEmpty ? 0 : 1; // skip shared junction point
      if (reversed) {
        for (var i = arc.length - 1; i >= start; i--) {
          ring.add(arc[i]);
        }
      } else {
        for (var i = start; i < arc.length; i++) {
          ring.add(arc[i]);
        }
      }
    }
    return ring;
  }

  final rings = <List<double>>[];

  void addRing(List<List<double>> pts) {
    // Simplify: keep every other point; drop degenerate rings.
    if (pts.length < 10) return;
    final flat = <double>[];
    for (var i = 0; i < pts.length; i += 2) {
      flat.add(double.parse(pts[i][0].toStringAsFixed(2)));
      flat.add(double.parse(pts[i][1].toStringAsFixed(2)));
    }
    if (flat.length >= 20) rings.add(flat);
  }

  void walkGeometry(Object? geo) {
    if (geo == null) return;
    final g = geo as Map<String, dynamic>;
    switch (g['type'] as String) {
      case 'GeometryCollection':
        for (final sub in g['geometries'] as List<dynamic>) {
          walkGeometry(sub);
        }
      case 'MultiPolygon':
        for (final poly in g['arcs'] as List<dynamic>) {
          for (final ringIdx in poly as List<dynamic>) {
            addRing(ringFromIndices(ringIdx as List<dynamic>));
          }
        }
      case 'Polygon':
        for (final ringIdx in g['arcs'] as List<dynamic>) {
          addRing(ringFromIndices(ringIdx as List<dynamic>));
        }
    }
  }

  walkGeometry((topo['objects'] as Map<String, dynamic>)['land']);

  final out = jsonEncode({'rings': rings});
  Directory('assets/map').createSync(recursive: true);
  File('assets/map/land.json').writeAsStringSync(out);
  stdout.writeln(
      'wrote assets/map/land.json — ${rings.length} rings, ${out.length ~/ 1024} KB');
}
