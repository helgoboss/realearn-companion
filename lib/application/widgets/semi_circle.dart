import 'dart:math' as math;
import 'package:flutter/material.dart';

class SemiCircle extends StatelessWidget {
  final double diameter;
  final double degrees;
  final Color color;

  const SemiCircle({
    Key? key,
    this.degrees = 180,
    this.diameter = 200,
    this.color = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SemiCirclePainter(degrees: this.degrees, color: this.color),
      size: Size(diameter, diameter),
    );
  }
}

class SemiCirclePainter extends CustomPainter {
  final double degrees;
  final Color color;

  SemiCirclePainter({required this.degrees, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const startDegrees = 90;
    Paint paint = Paint()..color = this.color;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.height / 2, size.width / 2),
        height: size.height,
        width: size.width,
      ),
      startDegrees * math.pi / 180,
      this.degrees * math.pi / 180,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
