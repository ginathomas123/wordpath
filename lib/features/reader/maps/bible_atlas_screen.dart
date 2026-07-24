import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/fonts.dart';
import '../../../app/widgets/app_icon_button.dart';
import 'bible_map_data.dart';

// Warm, printed-atlas palette.
const _sea = Color(0xFFF4ECDC);
const _land = Color(0xFFE7D9BD);
const _landStroke = Color(0xFFCBB994);
const _graticule = Color(0x2E9A855C);
const _accent = Color(0xFF7A1828);
const _neighborInk = Color(0xFF6B573B);
const _focusInk = Color(0xFF2A1B0E);

/// A stylized, pan/zoomable Bible atlas focused on one place, drawn entirely
/// with a [CustomPainter] (no tiles). Shows the located place with a confidence
/// halo when its position is uncertain, plus nearby places for context.
class BibleAtlasScreen extends StatelessWidget {
  final MapPlace focus;
  const BibleAtlasScreen({super.key, required this.focus});

  static const double _latSpan = 9.0;

  @override
  Widget build(BuildContext context) {
    final data = BibleGeo.data;
    final neighbors = BibleGeo.neighbors(focus);

    return Scaffold(
      backgroundColor: _sea,
      body: Stack(
        children: [
          Positioned.fill(
            child: data == null
                ? const SizedBox()
                : InteractiveViewer(
                    minScale: 0.6,
                    maxScale: 6,
                    boundaryMargin: const EdgeInsets.all(600),
                    child: CustomPaint(
                      painter: _AtlasPainter(
                        data: data,
                        focus: focus,
                        neighbors: neighbors,
                        latSpan: _latSpan,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
          ),

          // Title pill.
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 0,
            right: 0,
            child: Center(child: _TitlePill(place: focus)),
          ),

          // Back button.
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 8,
            child: AppIconButton(
              icon: LucideIcons.arrowLeft,
              tooltip: 'Back',
              background: const Color(0xCCFFFFFF),
              foreground: _focusInk,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),

          // Attribution — required by CC-BY.
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: Center(
              child: Text(
                'Places © OpenBible.info (CC BY) · Basemap © Natural Earth',
                style: AppFonts.sans(
                  fontSize: 9.5,
                  color: _neighborInk.withValues(alpha: 0.7),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitlePill extends StatelessWidget {
  final MapPlace place;
  const _TitlePill({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            place.name,
            style: AppFonts.serif(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _focusInk,
            ),
          ),
          if (place.approx)
            Text(
              'approximate location',
              style: AppFonts.sans(
                fontSize: 10,
                color: _accent.withValues(alpha: 0.8),
                letterSpacing: 0.3,
              ),
            ),
        ],
      ),
    );
  }
}

class _AtlasPainter extends CustomPainter {
  final BibleAtlasData data;
  final MapPlace focus;
  final List<MapPlace> neighbors;
  final double latSpan;

  _AtlasPainter({
    required this.data,
    required this.focus,
    required this.neighbors,
    required this.latSpan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerLat = focus.lat;
    final centerLon = focus.lon;
    final cosLat = math.cos(centerLat * math.pi / 180);
    final aspect = size.width / size.height;
    final lonSpan = aspect * latSpan / cosLat;

    final lon0 = centerLon - lonSpan / 2;
    final lat1 = centerLat + latSpan / 2;

    double px(double lon) => (lon - lon0) / lonSpan * size.width;
    double py(double lat) => (lat1 - lat) / latSpan * size.height;
    Offset proj(double lon, double lat) => Offset(px(lon), py(lat));

    // Sea background.
    canvas.drawRect(Offset.zero & size, Paint()..color = _sea);

    // Land.
    final landFill = Paint()..color = _land..style = PaintingStyle.fill;
    final landLine = Paint()
      ..color = _landStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round;
    for (final ring in data.land) {
      final path = Path();
      for (var i = 0; i < ring.length; i++) {
        final o = proj(ring[i].dx, ring[i].dy);
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      path.close();
      canvas.drawPath(path, landFill);
      canvas.drawPath(path, landLine);
    }

    // Graticule every 2°.
    final grat = Paint()
      ..color = _graticule
      ..strokeWidth = 0.5;
    for (var lon = lon0.ceilToDouble(); lon <= lon0 + lonSpan; lon += 2) {
      canvas.drawLine(Offset(px(lon), 0), Offset(px(lon), size.height), grat);
    }
    for (var lat = (lat1 - latSpan).ceilToDouble(); lat <= lat1; lat += 2) {
      canvas.drawLine(Offset(0, py(lat)), Offset(size.width, py(lat)), grat);
    }

    // Neighbor places.
    for (final p in neighbors) {
      final o = proj(p.lon, p.lat);
      canvas.drawCircle(o, 2.6, Paint()..color = _neighborInk.withValues(alpha: 0.75));
      _label(canvas, p.name, o + const Offset(7, -6), _neighborInk, 11,
          FontWeight.w500);
    }

    // Focus — confidence halo (if approximate), then marker + label.
    final f = proj(focus.lon, focus.lat);
    if (focus.approx) {
      const r = 46.0;
      final halo = Paint()
        ..shader = RadialGradient(
          colors: [
            _accent.withValues(alpha: 0.26),
            _accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: f, radius: r));
      canvas.drawCircle(f, r, halo);
    }
    // Marker: white halo ring + accent dot.
    canvas.drawCircle(f, 8.5, Paint()..color = Colors.white);
    canvas.drawCircle(
        f, 8.5, Paint()
      ..color = _accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    canvas.drawCircle(f, 5, Paint()..color = _accent);

    _label(canvas, focus.name, f + const Offset(0, -30), _focusInk, 15,
        FontWeight.w700, center: true, background: true);
  }

  void _label(Canvas canvas, String text, Offset at, Color color, double size,
      FontWeight weight,
      {bool center = false, bool background = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: AppFonts.serif(fontSize: size, fontWeight: weight, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var origin = at;
    if (center) origin = at - Offset(tp.width / 2, tp.height / 2);
    if (background) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx - 6, origin.dy - 3, tp.width + 12, tp.height + 6),
        const Radius.circular(6),
      );
      canvas.drawRRect(r, Paint()..color = const Color(0xE6FFFFFF));
    }
    tp.paint(canvas, origin);
  }

  @override
  bool shouldRepaint(_AtlasPainter old) => old.focus != focus;
}
