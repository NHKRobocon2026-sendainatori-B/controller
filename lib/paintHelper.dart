import 'dart:math';
import 'package:flutter/material.dart';

///矢印を描画する関数
void drawArrow(
  Canvas canvas,
  Offset start,
  Offset end,
  Color color,
  {
    double strokeWidth = 3.0,
    double arrowSize = 12.0
  }
){
  final paint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  canvas.drawLine(start, end, paint); //線を描画

  final angle = atan2(end.dy - start.dy, end.dx - start.dx);

  final arrowPath = Path();

  arrowPath.moveTo(end.dx, end.dy);

  arrowPath.lineTo(
    end.dx - arrowSize * cos(angle - pi / 6), 
    end.dy - arrowSize * sin(angle - pi / 6)
  );
  arrowPath.lineTo(
    end.dx - arrowSize * cos(angle + pi / 6), 
    end.dy - arrowSize * sin(angle + pi / 6)
  );
  arrowPath.close();
  final arrowPaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  canvas.drawPath(arrowPath, arrowPaint);
}

///点線を書く関数
void drawDashedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Color color,
  {
    double strokeWidth = 3.0,
    double dashWidth = 6.0,
    double dashSpace = 4.0
  }
){
  final paint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  
  final double dx = end.dx - start.dx;
  final double dy = end.dy - start.dy;
  final double totalDis = sqrt(dx * dx + dy * dy);

  if (totalDis <= 0) return;

  final double unitX = dx / totalDis;
  final double unitY = dy / totalDis;

  double currentdis = 0.0;

  while (currentdis < totalDis) {
    final lineEndDis = min(currentdis + dashWidth, totalDis);

    final Offset p1 = Offset(
      start.dx + unitX * currentdis,
      start.dy + unitY * currentdis
    );
    final Offset p2 = Offset(
      start.dx + unitX * lineEndDis,
      start.dy + unitY * lineEndDis
    );

    canvas.drawLine(p1, p2, paint);

    currentdis += dashWidth + dashSpace;
  }
}

///円弧などを書く関数
void drawArc(
  Canvas canvas,
  Offset center, //中心位置
  double radius, //半径
  double startAngleDeg, //開始角度 (90度法)
  double sweepAngleDeg, //描画範囲 (90度法)
  Color color,
  {
    double strokeWidth = 3.0,
    bool useCenter = false, //中心と結び扇形にするなら true
    bool isDashed = false, //点線にするなら true
    double dashWidth = 6.0, //点線の長さ
    double dashSpace = 4.0 //点線の空白の長さ
  }
) {
  final double startAngleRad = startAngleDeg * (pi / 180);
  final double sweepAngleRad = sweepAngleDeg * (pi / 180);

  final rect = Rect.fromCircle(center: center, radius: radius);

  final paint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..style = useCenter ? PaintingStyle.fill : PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  if (isDashed) {
    final path = Path()
      ..addArc(rect, startAngleRad, sweepAngleRad);
    double dashWidth = 6.0;
    double dashSpace = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double nextDis = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, nextDis), 
          paint
        );
        distance = nextDis + dashSpace;
      }
    }
  } else {
    canvas.drawArc(
      rect, 
      startAngleRad, 
      sweepAngleRad, 
      useCenter, 
      paint
    );
  }
}

///回転した長方形を書く
void drawRotatedRect(
  Canvas canvas,
  Offset center,
  double width,
  double height,
  double angleDeg,
  Color color,
  {
    double strokeWidth = 2.0,
    bool isFilled = false //塗りつぶすかどうか
  }
){
  final double angleRad = angleDeg * (pi / 180);
  final paint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke;
  
  canvas.save();

  canvas.translate(center.dx, center.dy);

  canvas.rotate(angleRad);

  final rect = Rect.fromLTWH(-width / 2, -height / 2, width, height);
  canvas.drawRect(rect, paint);

  canvas.restore();
}