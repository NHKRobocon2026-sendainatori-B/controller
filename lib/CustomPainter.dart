import 'package:flutter/material.dart';

class RobotMapPainter extends CustomPainter {
  final double robotX; //ROS2でのX座標（メートル）
  final double robotY; //ROS2でのy座標（メートル）

  // フィールドの実際のサイズ（メートル）
  final double fieldWidthMeters = 10.0;
  final double fieldHeightMeters = 10.0;

  RobotMapPainter({required this.robotX, required this.robotY});

  @override
  void paint(Canvas canvas , Size size) {
    final double px = (robotX / fieldHeightMeters) * size.width;
    final double py = size.height - ((robotY / fieldHeightMeters) * size.height);

    final robotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final clampedX = px.clamp(0.0, size.width);
    final clampedY = py.clamp(0.0, size.height);
    final center = Offset(clampedX, clampedY);

    canvas.drawCircle(center, 12.0, robotPaint);
    canvas.drawCircle(center, 12.0, borderPaint);
  }

  @override
  bool shouldRepaint(covariant RobotMapPainter oldDelegate){
    return oldDelegate.robotX != robotX || oldDelegate.robotY != robotY;
  }
}