import 'package:flutter/material.dart';

class ReloopBackground extends StatelessWidget {
  final Widget child;
  final Color color;

  const ReloopBackground({
    super.key,
    required this.child,
    this.color = const Color(0xFFF4F6F4),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotGridPainter(),
      child: Container(color: color, child: child),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x180B5D4B);
    const gap = 18.0;
    for (double x = 9; x < size.width; x += gap) {
      for (double y = 9; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
