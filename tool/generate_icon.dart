// ignore_for_file: avoid_print
/// Generates a 1024x1024 PNG app icon for Typer Kids.
/// Uses pure Dart to write a valid PNG with a colorful keyboard-themed design.
/// Run: dart run tool/generate_icon.dart
library;

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Background: rounded gradient (purple → blue)
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final t = y / size;
      // Warm purple-to-blue gradient
      final r = _lerp(106, 33, t).round(); // purple → blue
      final g = _lerp(27, 150, t).round();
      final b = _lerp(154, 243, t).round();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Draw rounded rectangle mask (round the corners)
  const cornerRadius = 200;
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      if (!_inRoundedRect(x, y, 0, 0, size, size, cornerRadius)) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  // Draw keyboard keys (3 rows)
  final keyRows = [
    ['T', 'Y', 'P', 'E', 'R'],
    ['K', 'I', 'D', 'S', '!'],
  ];

  const keySize = 130;
  const keyGap = 18;
  const keyRadius = 24;

  for (int row = 0; row < keyRows.length; row++) {
    final keys = keyRows[row];
    final totalW = keys.length * keySize + (keys.length - 1) * keyGap;
    final startX = (size - totalW) ~/ 2;
    final startY = 240 + row * (keySize + keyGap);

    for (int k = 0; k < keys.length; k++) {
      final kx = startX + k * (keySize + keyGap);
      final ky = startY;

      // Key shadow
      _fillRoundedRect(
        image,
        kx + 4,
        ky + 6,
        keySize,
        keySize,
        keyRadius,
        0,
        0,
        0,
        60,
      );

      // Key background (white with slight transparency)
      _fillRoundedRect(
        image,
        kx,
        ky,
        keySize,
        keySize,
        keyRadius,
        255,
        255,
        255,
        230,
      );

      // Key border
      _drawRoundedRectBorder(
        image,
        kx,
        ky,
        keySize,
        keySize,
        keyRadius,
        200,
        200,
        220,
        180,
        3,
      );

      // Draw letter
      _drawLetter(image, keys[k], kx, ky, keySize);
    }
  }

  // Draw colorful sparkles/stars around
  final rng = Random(42);
  final sparkleColors = [
    [255, 193, 7], // amber
    [76, 175, 80], // green
    [233, 30, 99], // pink
    [0, 188, 212], // cyan
    [255, 87, 34], // deep orange
  ];

  for (int i = 0; i < 12; i++) {
    final sx = 80 + rng.nextInt(size - 160);
    final sy = rng.nextBool() ? (80 + rng.nextInt(140)) : (680 + rng.nextInt(200));
    final sc = sparkleColors[i % sparkleColors.length];
    final starSize = 14 + rng.nextInt(18);
    _drawStar(image, sx, sy, starSize, sc[0], sc[1], sc[2]);
  }

  // Encode to PNG
  final png = img.encodePng(image);
  final dir = Directory('assets');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File('assets/app_icon.png').writeAsBytesSync(png);
  print('✓ Generated assets/app_icon.png (${size}x$size)');
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

bool _inRoundedRect(
  int x,
  int y,
  int rx,
  int ry,
  int rw,
  int rh,
  int radius,
) {
  // Check if point is inside rounded rect
  if (x < rx || x >= rx + rw || y < ry || y >= ry + rh) return false;

  // Check corners
  final corners = [
    [rx + radius, ry + radius], // top-left
    [rx + rw - radius, ry + radius], // top-right
    [rx + radius, ry + rh - radius], // bottom-left
    [rx + rw - radius, ry + rh - radius], // bottom-right
  ];

  for (final c in corners) {
    final cx = c[0], cy = c[1];
    final inCornerRegion =
        (x < rx + radius && y < ry + radius) || // top-left
        (x >= rx + rw - radius && y < ry + radius) || // top-right
        (x < rx + radius && y >= ry + rh - radius) || // bottom-left
        (x >= rx + rw - radius && y >= ry + rh - radius); // bottom-right

    if (inCornerRegion) {
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy > radius * radius) return false;
    }
  }
  return true;
}

void _fillRoundedRect(
  img.Image image,
  int rx,
  int ry,
  int rw,
  int rh,
  int radius,
  int r,
  int g,
  int b,
  int a,
) {
  for (int y = ry; y < ry + rh && y < image.height; y++) {
    for (int x = rx; x < rx + rw && x < image.width; x++) {
      if (x < 0 || y < 0) continue;
      if (_inRoundedRect(x, y, rx, ry, rw, rh, radius)) {
        if (a < 255) {
          // Alpha blend
          final existing = image.getPixel(x, y);
          final er = existing.r.toInt();
          final eg = existing.g.toInt();
          final eb = existing.b.toInt();
          final alpha = a / 255.0;
          final nr = (r * alpha + er * (1 - alpha)).round();
          final ng = (g * alpha + eg * (1 - alpha)).round();
          final nb = (b * alpha + eb * (1 - alpha)).round();
          image.setPixelRgba(x, y, nr, ng, nb, 255);
        } else {
          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    }
  }
}

void _drawRoundedRectBorder(
  img.Image image,
  int rx,
  int ry,
  int rw,
  int rh,
  int radius,
  int r,
  int g,
  int b,
  int a,
  int thickness,
) {
  for (int y = ry; y < ry + rh && y < image.height; y++) {
    for (int x = rx; x < rx + rw && x < image.width; x++) {
      if (x < 0 || y < 0) continue;
      if (_inRoundedRect(x, y, rx, ry, rw, rh, radius) &&
          !_inRoundedRect(
            x,
            y,
            rx + thickness,
            ry + thickness,
            rw - thickness * 2,
            rh - thickness * 2,
            radius - thickness,
          )) {
        final existing = image.getPixel(x, y);
        final er = existing.r.toInt();
        final eg = existing.g.toInt();
        final eb = existing.b.toInt();
        final alpha = a / 255.0;
        final nr = (r * alpha + er * (1 - alpha)).round();
        final ng = (g * alpha + eg * (1 - alpha)).round();
        final nb = (b * alpha + eb * (1 - alpha)).round();
        image.setPixelRgba(x, y, nr, ng, nb, 255);
      }
    }
  }
}

// Simple bitmap font for capital letters - 5x7 grid per character
final Map<String, List<String>> _font = {
  'T': [
    'XXXXX',
    '  X  ',
    '  X  ',
    '  X  ',
    '  X  ',
    '  X  ',
    '  X  ',
  ],
  'Y': [
    'X   X',
    'X   X',
    ' X X ',
    '  X  ',
    '  X  ',
    '  X  ',
    '  X  ',
  ],
  'P': [
    'XXXX ',
    'X   X',
    'X   X',
    'XXXX ',
    'X    ',
    'X    ',
    'X    ',
  ],
  'E': [
    'XXXXX',
    'X    ',
    'X    ',
    'XXXX ',
    'X    ',
    'X    ',
    'XXXXX',
  ],
  'R': [
    'XXXX ',
    'X   X',
    'X   X',
    'XXXX ',
    'X X  ',
    'X  X ',
    'X   X',
  ],
  'K': [
    'X   X',
    'X  X ',
    'X X  ',
    'XX   ',
    'X X  ',
    'X  X ',
    'X   X',
  ],
  'I': [
    'XXXXX',
    '  X  ',
    '  X  ',
    '  X  ',
    '  X  ',
    '  X  ',
    'XXXXX',
  ],
  'D': [
    'XXXX ',
    'X   X',
    'X   X',
    'X   X',
    'X   X',
    'X   X',
    'XXXX ',
  ],
  'S': [
    ' XXXX',
    'X    ',
    'X    ',
    ' XXX ',
    '    X',
    '    X',
    'XXXX ',
  ],
  '!': [
    '  X  ',
    '  X  ',
    '  X  ',
    '  X  ',
    '  X  ',
    '     ',
    '  X  ',
  ],
};

void _drawLetter(img.Image image, String letter, int kx, int ky, int keySize) {
  final glyph = _font[letter];
  if (glyph == null) return;

  const glyphW = 5;
  const glyphH = 7;
  final pixelSize = (keySize * 0.55 / glyphH).round();
  final letterW = glyphW * pixelSize;
  final letterH = glyphH * pixelSize;
  final offsetX = kx + (keySize - letterW) ~/ 2;
  final offsetY = ky + (keySize - letterH) ~/ 2;

  // Color: rich purple for letters
  const lr = 90, lg = 24, lb = 154;

  for (int row = 0; row < glyphH; row++) {
    for (int col = 0; col < glyphW; col++) {
      if (glyph[row][col] == 'X') {
        for (int py = 0; py < pixelSize; py++) {
          for (int px = 0; px < pixelSize; px++) {
            final x = offsetX + col * pixelSize + px;
            final y = offsetY + row * pixelSize + py;
            if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
              image.setPixelRgba(x, y, lr, lg, lb, 255);
            }
          }
        }
      }
    }
  }
}

void _drawStar(
  img.Image image,
  int cx,
  int cy,
  int radius,
  int r,
  int g,
  int b,
) {
  // Draw a simple 4-pointed star
  for (int dy = -radius; dy <= radius; dy++) {
    for (int dx = -radius; dx <= radius; dx++) {
      final ax = dx.abs();
      final ay = dy.abs();
      // Diamond shape with glow
      if (ax + ay <= radius) {
        final dist = (ax + ay) / radius;
        final alpha = ((1 - dist) * 220).round().clamp(0, 255);
        final x = cx + dx;
        final y = cy + dy;
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          final existing = image.getPixel(x, y);
          final er = existing.r.toInt();
          final eg = existing.g.toInt();
          final eb = existing.b.toInt();
          final a = alpha / 255.0;
          final nr = (r * a + er * (1 - a)).round();
          final ng = (g * a + eg * (1 - a)).round();
          final nb = (b * a + eb * (1 - a)).round();
          image.setPixelRgba(x, y, nr, ng, nb, 255);
        }
      }
    }
  }
}
