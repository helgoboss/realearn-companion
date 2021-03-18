import 'dart:math' as math;
import 'package:flutter/material.dart';

class SemiCircle extends StatelessWidget {
  final double diameter;
  final double degrees;
  final Color color;
  final bool fill;

  const SemiCircle({
    Key? key,
    this.degrees = 180,
    this.diameter = 200,
    this.color = Colors.blue,
    this.fill = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SemiCirclePainter(
        degrees: this.degrees,
        color: this.color,
        fill: this.fill,
      ),
      size: Size(diameter, diameter),
    );
  }
}

class SemiCirclePainter extends CustomPainter {
  final double degrees;
  final Color color;
  final bool fill;

  SemiCirclePainter({
    required this.degrees,
    required this.color,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const startDegrees = 90;
    Paint paint = Paint()
      ..color = this.color
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.height / 2, size.width / 2),
        height: size.height,
        width: size.width,
      ),
      startDegrees * math.pi / 180,
      this.degrees * math.pi / 180,
      fill,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
