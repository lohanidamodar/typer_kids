import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pagoda painter
// ─────────────────────────────────────────────────────────────────────────────

class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Far mountains (lighter, behind)
    final farPaint = Paint()..color = const Color(0xFF0D0825);
    final far = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.7)
      ..lineTo(w * 0.10, h * 0.35)
      ..lineTo(w * 0.22, h * 0.55)
      ..lineTo(w * 0.35, h * 0.20)
      ..lineTo(w * 0.48, h * 0.50)
      ..lineTo(w * 0.55, h * 0.30)
      ..lineTo(w * 0.65, h * 0.15)
      ..lineTo(w * 0.75, h * 0.45)
      ..lineTo(w * 0.85, h * 0.25)
      ..lineTo(w * 0.95, h * 0.50)
      ..lineTo(w, h * 0.60)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(far, farPaint);

    // Near mountains (darker, in front)
    final nearPaint = Paint()..color = const Color(0xFF0A0620);
    final near = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.65)
      ..lineTo(w * 0.08, h * 0.50)
      ..lineTo(w * 0.18, h * 0.70)
      ..lineTo(w * 0.30, h * 0.40)
      ..lineTo(w * 0.42, h * 0.65)
      ..lineTo(w * 0.52, h * 0.45)
      ..lineTo(w * 0.60, h * 0.60)
      ..lineTo(w * 0.72, h * 0.35)
      ..lineTo(w * 0.82, h * 0.55)
      ..lineTo(w * 0.92, h * 0.40)
      ..lineTo(w, h * 0.55)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(near, nearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class PagodaPainter extends CustomPainter {
  final bool damageFlash;

  PagodaPainter({this.damageFlash = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Palette ──
    final wallColor =
        damageFlash ? const Color(0xFF8B2020) : const Color(0xFF5C3A1E);
    final roofColor =
        damageFlash ? const Color(0xFFCC2020) : const Color(0xFF8B1A1A);
    final roofAccent =
        damageFlash ? const Color(0xFFFF4444) : const Color(0xFFD4AF37);
    final grassDark = const Color(0xFF1B4332);
    final grassLight = const Color(0xFF2D6A4F);
    final treeTrunk = const Color(0xFF3E2723);
    final treeLeaf = const Color(0xFF1B5E20);
    final treeLeafLight = const Color(0xFF2E7D32);
    final stoneColor = const Color(0xFF37474F);
    final lanternGlow =
        damageFlash ? const Color(0xFFFF4444) : const Color(0xFFFFAB00);

    // ── Ground ──
    // Dark earth base
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
      Paint()..color = const Color(0xFF1A0F05),
    );
    // Grass layer
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.75, w, h * 0.08),
      Paint()..color = grassDark,
    );
    // Grass highlights — small bumps across the width
    final grassPath = Path()..moveTo(0, h * 0.76);
    for (var x = 0.0; x < w; x += 8) {
      grassPath.lineTo(x + 4, h * 0.73);
      grassPath.lineTo(x + 8, h * 0.76);
    }
    grassPath.lineTo(w, h * 0.78);
    grassPath.lineTo(0, h * 0.78);
    grassPath.close();
    canvas.drawPath(grassPath, Paint()..color = grassLight);

    // ── Stone path to temple ──
    final pathW = w * 0.08;
    for (var i = 0; i < 4; i++) {
      final sy = h * 0.80 + i * h * 0.05;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - pathW / 2, sy, pathW, h * 0.03),
          const Radius.circular(3),
        ),
        Paint()..color = stoneColor.withValues(alpha: 0.6 - i * 0.1),
      );
    }

    // ── Trees ── (left and right sides)
    void drawTree(double tx, double scale) {
      final trunkW = 6.0 * scale;
      final trunkH = h * 0.25 * scale;
      final trunkTop = h * 0.75 - trunkH;

      // Trunk
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tx - trunkW / 2, trunkTop, trunkW, trunkH),
          const Radius.circular(2),
        ),
        Paint()..color = treeTrunk,
      );

      // Foliage layers (3 triangles)
      for (var i = 0; i < 3; i++) {
        final layerW = (28.0 - i * 6) * scale;
        final layerH = (18.0 - i * 2) * scale;
        final layerY = trunkTop - i * layerH * 0.6;
        final p = Path()
          ..moveTo(tx - layerW / 2, layerY)
          ..lineTo(tx, layerY - layerH)
          ..lineTo(tx + layerW / 2, layerY)
          ..close();
        canvas.drawPath(p, Paint()..color = i.isEven ? treeLeaf : treeLeafLight);
      }
    }

    // Left trees
    drawTree(w * 0.06, 0.8);
    drawTree(w * 0.15, 1.0);
    drawTree(w * 0.24, 0.7);
    // Right trees
    drawTree(w * 0.76, 0.7);
    drawTree(w * 0.85, 1.0);
    drawTree(w * 0.94, 0.8);

    // ── Side shrines ── (small pagodas on left and right)
    void drawShrine(double sx) {
      final sw = w * 0.08;
      final sh = h * 0.25;
      final sTop = h * 0.75 - sh;

      // Body
      canvas.drawRect(
        Rect.fromLTWH(sx - sw / 2, sTop + sh * 0.4, sw, sh * 0.6),
        Paint()..color = wallColor.withValues(alpha: 0.8),
      );
      // Door
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(sx - sw * 0.15, sTop + sh * 0.6, sw * 0.3, sh * 0.4),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFF0A0505),
      );
      // Roof
      final rp = Path()
        ..moveTo(sx - sw * 0.7, sTop + sh * 0.4)
        ..lineTo(sx, sTop + sh * 0.15)
        ..lineTo(sx + sw * 0.7, sTop + sh * 0.4)
        ..close();
      canvas.drawPath(rp, Paint()..color = roofColor);
      canvas.drawPath(
        rp,
        Paint()
          ..color = roofAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    drawShrine(w * 0.30);
    drawShrine(w * 0.70);

    // ── Lanterns ── (stone posts with glowing tops)
    void drawLantern(double lx) {
      final postH = h * 0.12;
      final postTop = h * 0.75 - postH;
      // Post
      canvas.drawRect(
        Rect.fromLTWH(lx - 2, postTop, 4, postH),
        Paint()..color = stoneColor,
      );
      // Glow
      canvas.drawCircle(
        Offset(lx, postTop - 2),
        5,
        Paint()..color = lanternGlow.withValues(alpha: 0.7),
      );
      canvas.drawCircle(
        Offset(lx, postTop - 2),
        10,
        Paint()
          ..color = lanternGlow.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    drawLantern(w * 0.38);
    drawLantern(w * 0.62);

    // ── Main Pagoda Temple (center) ──
    final bodyW = w * 0.22;
    final bodyH = h * 0.35;
    final bodyTop = h * 0.75 - bodyH;
    final bodyL = cx - bodyW / 2;

    // Temple body
    canvas.drawRect(
      Rect.fromLTWH(bodyL, bodyTop + bodyH * 0.35, bodyW, bodyH * 0.65),
      Paint()..color = wallColor,
    );

    // Pillars
    final pillarW = bodyW * 0.06;
    for (final px in [bodyL + bodyW * 0.15, bodyL + bodyW * 0.85 - pillarW]) {
      canvas.drawRect(
        Rect.fromLTWH(px, bodyTop + bodyH * 0.38, pillarW, bodyH * 0.6),
        Paint()..color = roofAccent.withValues(alpha: 0.4),
      );
    }

    // Door
    final doorW = bodyW * 0.25;
    final doorH = bodyH * 0.35;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - doorW / 2, bodyTop + bodyH - doorH, doorW, doorH),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF0A0505),
    );
    // Door glow
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - doorW / 2, bodyTop + bodyH - doorH, doorW, doorH),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ),
      Paint()
        ..color = lanternGlow.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Roof tiers (3 levels)
    for (var i = 0; i < 3; i++) {
      final tierScale = 1.0 - i * 0.25;
      final tierW = (bodyW + 30) * tierScale;
      final tierH = bodyH * 0.1;
      final tierY = bodyTop + bodyH * 0.32 - i * tierH * 1.4;

      final path = Path()
        ..moveTo(cx - tierW / 2 - 8, tierY + tierH)
        ..quadraticBezierTo(cx - tierW / 2 - 14, tierY + tierH - 4,
            cx - tierW * 0.35, tierY)
        ..lineTo(cx + tierW * 0.35, tierY)
        ..quadraticBezierTo(
            cx + tierW / 2 + 14, tierY + tierH - 4,
            cx + tierW / 2 + 8, tierY + tierH)
        ..close();
      canvas.drawPath(path, Paint()..color = roofColor);
      canvas.drawPath(
        path,
        Paint()
          ..color = roofAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Spire
    final spireBase = bodyTop + bodyH * 0.32 - 3 * (bodyH * 0.1) * 1.4;
    final spireTop = spireBase - h * 0.06;
    canvas.drawLine(
      Offset(cx, spireTop),
      Offset(cx, spireBase + 4),
      Paint()
        ..color = roofAccent
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset(cx, spireTop),
      4,
      Paint()..color = roofAccent,
    );
    // Spire glow
    canvas.drawCircle(
      Offset(cx, spireTop),
      8,
      Paint()
        ..color = lanternGlow.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant PagodaPainter old) =>
      damageFlash != old.damageFlash;
}
