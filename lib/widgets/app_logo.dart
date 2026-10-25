import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF177245),
              const Color(0xFF22963F),
              const Color(0xFF1AAA4A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF177245).withValues(alpha: 0.35),
              blurRadius: size * 0.2,
              offset: Offset(0, size * 0.06),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _LogoPainter(),
          child: Center(
            child: Icon(
              Icons.recycling_rounded,
              size: size * 0.55,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer circle glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;
    canvas.drawCircle(center, size.width * 0.42, glowPaint);

    // Inner subtle ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;
    canvas.drawCircle(center, size.width * 0.32, ringPaint);

    // Small decorative dots
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.25);
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final dotCenter = Offset(
        center.dx + math.cos(angle) * size.width * 0.42,
        center.dy + math.sin(angle) * size.height * 0.42,
      );
      canvas.drawCircle(dotCenter, size.width * 0.018, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
