import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../data/keyboard_data.dart';

/// Shows which finger to use for the current key, with a visual hand diagram
/// that highlights the correct finger above the keyboard.
class FingerGuide extends StatelessWidget {
  final String? currentKey;

  const FingerGuide({super.key, this.currentKey});

  @override
  Widget build(BuildContext context) {
    if (currentKey == null) return const SizedBox.shrink();

    final finger = KeyboardData.keyToFinger[currentKey!.toLowerCase()];
    if (finger == null) return const SizedBox.shrink();

    final fingerName = KeyboardData.fingerNameForKey(currentKey!);
    final fingerColor = KeyboardData.fingerColor(finger);
    final isLeft = finger.startsWith('left');
    final isThumb = finger == 'thumb';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hand diagram showing active finger
        SizedBox(
          height: 80,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HandDiagram(
                isLeft: true,
                activeFinger: isLeft ? finger : (isThumb ? 'thumb' : null),
              ),
              const SizedBox(width: 12),
              _HandDiagram(
                isLeft: false,
                activeFinger: !isLeft ? finger : (isThumb ? 'thumb' : null),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Finger label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: fingerColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: fingerColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            fingerName,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Draws a single hand (left or right) with fingers as rounded shapes.
/// The active finger is highlighted with a glow.
class _HandDiagram extends StatelessWidget {
  final bool isLeft;
  final String? activeFinger;

  const _HandDiagram({required this.isLeft, this.activeFinger});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(90, 80),
      painter: _HandPainter(
        isLeft: isLeft,
        activeFinger: activeFinger,
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  final bool isLeft;
  final String? activeFinger;

  _HandPainter({required this.isLeft, this.activeFinger});

  // Finger layout: each finger has (centerX fraction, top fraction, height fraction, width)
  // Ordered: pinky, ring, middle, index, thumb
  static const _leftFingerData = <_FingerSpec>[
    _FingerSpec(0.12, 0.35, 0.38, 10, 'left-pinky'),
    _FingerSpec(0.30, 0.15, 0.50, 11, 'left-ring'),
    _FingerSpec(0.48, 0.05, 0.58, 11, 'left-middle'),
    _FingerSpec(0.66, 0.18, 0.48, 11, 'left-index'),
    _FingerSpec(0.84, 0.52, 0.30, 12, 'thumb'),
  ];

  static const _rightFingerData = <_FingerSpec>[
    _FingerSpec(0.16, 0.52, 0.30, 12, 'thumb'),
    _FingerSpec(0.34, 0.18, 0.48, 11, 'right-index'),
    _FingerSpec(0.52, 0.05, 0.58, 11, 'right-middle'),
    _FingerSpec(0.70, 0.15, 0.50, 11, 'right-ring'),
    _FingerSpec(0.88, 0.35, 0.38, 10, 'right-pinky'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final fingers = isLeft ? _leftFingerData : _rightFingerData;

    // Draw palm
    final palmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.55,
        size.width * 0.90,
        size.height * 0.42,
      ),
      const Radius.circular(12),
    );
    final palmPaint = Paint()
      ..color = const Color(0xFFFFE0B2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(palmRect, palmPaint);

    final palmBorder = Paint()
      ..color = const Color(0xFFD7A97A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(palmRect, palmBorder);

    // Draw each finger
    for (final spec in fingers) {
      final isActive = activeFinger == spec.fingerName;
      final color = KeyboardData.fingerColor(spec.fingerName);

      final cx = size.width * spec.centerXFrac;
      final top = size.height * spec.topFrac;
      final h = size.height * spec.heightFrac;
      final w = spec.width.toDouble();

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, top + h / 2), width: w, height: h),
        Radius.circular(w / 2),
      );

      // Glow for active finger
      if (isActive) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, top + h / 2),
              width: w + 8,
              height: h + 8,
            ),
            Radius.circular((w + 8) / 2),
          ),
          glowPaint,
        );
      }

      // Finger fill
      final fillPaint = Paint()
        ..color = isActive ? color : const Color(0xFFFFE0B2)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, fillPaint);

      // Finger border
      final borderPaint = Paint()
        ..color = isActive ? color.withValues(alpha: 0.9) : const Color(0xFFD7A97A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 2.0 : 1.2;
      canvas.drawRRect(rect, borderPaint);

      // Fingernail hint
      final nailTop = top + 2;
      final nailRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, nailTop + 3),
          width: w * 0.6,
          height: 5,
        ),
        const Radius.circular(2),
      );
      final nailPaint = Paint()
        ..color = isActive
            ? Colors.white.withValues(alpha: 0.7)
            : const Color(0xFFF5D5B8)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(nailRect, nailPaint);
    }

    // Hand label
    final labelSpan = TextSpan(
      text: isLeft ? 'L' : 'R',
      style: const TextStyle(
        color: Color(0xFFBE8C5E),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
    final tp = TextPainter(
      text: labelSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        (size.width - tp.width) / 2,
        size.height * 0.70,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) =>
      activeFinger != oldDelegate.activeFinger || isLeft != oldDelegate.isLeft;
}

class _FingerSpec {
  final double centerXFrac;
  final double topFrac;
  final double heightFrac;
  final int width;
  final String fingerName;

  const _FingerSpec(
    this.centerXFrac,
    this.topFrac,
    this.heightFrac,
    this.width,
    this.fingerName,
  );
}
