import 'dart:math';
import 'package:flutter/material.dart';
import 'paintHelper.dart';

class SteeringPage extends CustomPainter {
  final List<Unit> units;
  final ValueNotifier<List<double>> anglesNotifier;

  SteeringPage({
    required this.units,
    required this.anglesNotifier
  }) : super(repaint: anglesNotifier);

  @override
  void paint(Canvas canvas , Size size) {
    //枠
    final rect = Rect.fromLTRB(size.width * 0.2, size.height * 0.2, size.width * 0.8, size.height * 0.8);
    final rectPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      rect, 
      rectPaint
    );

    //中心点
    final paint = Paint()
      ..color = Colors.pink
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2), 
      20, 
      paint
    );

    //矢印
    final length = size.height / 4;
    final p1 = Offset(size.width / 2, size.height / 2);
    final p2 = Offset(size.width / 2, size.height / 2 - length);
    drawArrow(
      canvas, 
      p1, 
      p2, 
      Colors.purple,
      strokeWidth: 5.0
    );

    final angles = anglesNotifier.value;
    for (int i = 0; i < units.length; i++) {
      if (i < angles.length) {
        units[i].angle = angles[i];
      }
      units[i].draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant SteeringPage oldDelegate) {
    return false;
  }
}

class Unit {
  final Offset relativePosition;
  double angle;

  Unit({required this.relativePosition, required this.angle});

  void draw(Canvas canvas, Size size) {
    double dig = (angle + 180);
    double radian = dig * (pi / 180);

    final Offset position = Offset(
      size.width * relativePosition.dx, 
      size.height * relativePosition.dy
    );

    //横線
    Offset p1 = Offset(position.dx - 50, position.dy);
    Offset p2 = Offset(position.dx + 50, position.dy);
    Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(p1, p2, paint);

    final Color judgeColor = returnAngleColor(angle);
  
    //周りの円
    drawArc(
      canvas, position, 40, 
      0, 360, judgeColor,
      isDashed: true, 
      dashSpace: 8.0, 
      dashWidth: 0.3
    );

    //タイヤ
    drawRotatedRect(canvas, position, 30, 15, (angle + 180), Colors.black45, isFilled: true);

    //タイヤと直行する線
    p1 = Offset(position.dx + cos(radian - (pi / 2)) * 30, position.dy + sin(radian - (pi / 2)) * 30);
    p2 = Offset(position.dx + cos(radian + (pi / 2)) * 30, position.dy + sin(radian + (pi / 2)) * 30);
    drawDashedLine(canvas, p1, p2, Colors.greenAccent, strokeWidth: 4.0, dashSpace: 6.0, dashWidth: 1.0);

    //タイヤの向きと同じ矢印
    p1 = Offset(position.dx - cos(radian) * 10, position.dy - sin(radian) * 10);
    p2 = Offset(position.dx + cos(radian) * 40, position.dy + sin(radian) * 40);
    drawArrow(canvas, p1, p2, Colors.blue);

    //回転した角度を表す円弧
    drawArc(canvas, position, 35, 180, angle, judgeColor);
  }

  Color returnAngleColor(double angleRad) {
    if (angleRad < 0) {
      angleRad *= -1;
    }
    if (angleRad < 80) {
      return Colors.lightGreen;
    } else if (angleRad < 140){
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }
}