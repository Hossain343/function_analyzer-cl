import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// 1 / 2 / 5 × 10^k step that is >= raw.
double niceStep(double raw) {
  if (raw <= 0 || raw.isNaN || raw.isInfinite) return 1;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  for (final m in const [1.0, 2.0, 5.0, 10.0]) {
    if (m * mag >= raw) return m * mag;
  }
  return 10 * mag;
}

String fmtTick(double v, double step) {
  if (v.abs() < step * 1e-9) return '0';
  final dec = step >= 1
      ? 0
      : math.max(0, math.min(8, -(math.log(step) / math.ln10).floor()));
  return v.toStringAsFixed(dec);
}

void drawText(
  Canvas canvas,
  String text,
  Offset anchor, {
  required double size,
  required Color color,
  FontWeight weight = FontWeight.w500,
  double ax = 0.5,
  double ay = 0.5,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: mono(size, color: color, weight: weight)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(anchor.dx - tp.width * ax, anchor.dy - tp.height * ay));
}

/// Filled arrow head. [dir] is the unit vector the arrow points to.
void drawTriangle(Canvas canvas, Offset tip, Offset dir, double size, Color color) {
  final n = Offset(-dir.dy, dir.dx);
  final base = tip - dir * size;
  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(base.dx + n.dx * size * 0.55, base.dy + n.dy * size * 0.55)
    ..lineTo(base.dx - n.dx * size * 0.55, base.dy - n.dy * size * 0.55)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}
