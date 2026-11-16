import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/rational.dart';
import 'chart_utils.dart';
import 'theme.dart';
import 'widgets.dart';

const _canvasBg = Color(0xFF0B0C0F);

class GraphPage extends StatefulWidget {
  final AnalysisResult r;
  const GraphPage({super.key, required this.r});
  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  double _cx = 0;
  double _cy = 0;
  double _sx = 30;
  double _sy = 30;
  double _w = 300;
  double _h = 200;
  bool _needFit = true;

  void _fit() {
    final r = widget.r;
    final p = r.poly;
    final dom = r.domain;
    final xs = <double>[0];
    final ys = <double>[0];

    if (dom is SetDomain) {
      for (final x in dom.values) {
        xs.add(x.toDouble());
        ys.add(p.eval(x).toDouble());
      }
    } else if (dom is IntervalDomain) {
      final lo = dom.lo?.toDouble();
      final hi = dom.hi?.toDouble();
      final vx = p.isQuadratic
          ? (-p.c1 / (Rational.two * p.c2)).toDouble()
          : null;
      double a;
      double b;
      if (lo != null && hi != null) {
        a = lo;
        b = hi;
      } else if (lo != null) {
        a = lo;
        b = math.max(lo + 8, (vx != null && vx > lo) ? vx + 4 : lo + 8);
      } else if (hi != null) {
        b = hi;
        a = math.min(hi - 8, (vx != null && vx < hi) ? vx - 4 : hi - 8);
      } else {
        final c = vx ?? 0;
        a = c - 5;
        b = c + 5;
      }
      xs.addAll([a, b]);
      final x0 = lo == null ? a : math.max(a, lo);
      final x1 = hi == null ? b : math.min(b, hi);
      for (var i = 0; i <= 80; i++) {
        ys.add(p.evalD(x0 + (x1 - x0) * i / 80));
      }
      if (vx != null && vx >= x0 && vx <= x1) ys.add(p.evalD(vx));
    }

    var xmin = xs.reduce(math.min);
    var xmax = xs.reduce(math.max);
    var ymin = ys.reduce(math.min);
    var ymax = ys.reduce(math.max);
    if (xmax - xmin < 1e-9) {
      xmin -= 1;
      xmax += 1;
    }
    if (ymax - ymin < 1e-9) {
      ymin -= 1;
      ymax += 1;
    }
    final px = (xmax - xmin) * 0.16;
    final py = (ymax - ymin) * 0.16;
    xmin -= px;
    xmax += px;
    ymin -= py;
    ymax += py;
    _sx = _w / (xmax - xmin);
    _sy = _h / (ymax - ymin);
    _cx = (xmin + xmax) / 2;
    _cy = (ymin + ymax) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final dim = Dim.of(context);
    final s = dim.s;
    final r = widget.r;
    final dom = r.domain;
    _h = dim.d * 0.46;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('GRAPH'),
        Text(r.funcText, style: mono(14 * s)),
        Text.rich(TextSpan(style: mono(14 * s), children: [
          const TextSpan(
              text: 'Rf',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          TextSpan(text: ' = ${r.range.notation}'),
        ])),
        Text('bounds ${r.range.bounds}', style: mono(14 * s)),
        Text(
          dom is SetDomain
              ? 'Isolated points only. No connecting curve.'
              : 'Continuous curve. Hollow end = excluded.',
          style: mono(14 * s),
        ),
        SizedBox(height: 10 * s),
        LayoutBuilder(builder: (context, box) {
          _w = box.maxWidth;
          if (_needFit) {
            _fit();
            _needFit = false;
          }
          // The canvas claims the touch immediately so dragging it pans the
          // plane instead of scrolling the page. Scroll by dragging anywhere
          // else on the page.
          return RawGestureDetector(
            gestures: {
              EagerGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                      () => EagerGestureRecognizer(), (_) {}),
            },
            child: Listener(
              onPointerMove: (e) => setState(() {
                _cx -= e.delta.dx / _sx;
                _cy += e.delta.dy / _sy;
              }),
              child: Container(
                height: _h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _canvasBg,
                  borderRadius: BorderRadius.circular(16 * s),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15 * s),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: GraphPainter(r: r, cx: _cx, cy: _cy, sx: _sx, sy: _sy, s: s),
                  ),
                ),
              ),
            ),
          );
        }),
        SizedBox(height: 10 * s),
        Text('Drag to pan the plane.', style: mono(13.5 * s)),
        SizedBox(height: 10 * s),
        ZoomRow(
          onMinus: () => setState(() {
            _sx /= 1.4;
            _sy /= 1.4;
          }),
          onPlus: () => setState(() {
            _sx *= 1.4;
            _sy *= 1.4;
          }),
          onFit: () => setState(_fit),
        ),
        SizedBox(height: 12 * s),
        Wrap(spacing: 16 * s, runSpacing: 8 * s, children: [
          if (dom is SetDomain)
            const LegendItem(icon: LegendDot(filled: true), text: 'Set point')
          else ...[
            const LegendItem(icon: LegendDot(filled: true), text: 'Closed end'),
            const LegendItem(icon: LegendDot(filled: false), text: 'Open end'),
          ],
        ]),
      ],
    );
  }
}

class GraphPainter extends CustomPainter {
  final AnalysisResult r;
  final double cx;
  final double cy;
  final double sx;
  final double sy;
  final double s;
  GraphPainter({
    required this.r,
    required this.cx,
    required this.cy,
    required this.sx,
    required this.sy,
    required this.s,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.clipRect(Offset.zero & size);
    double px(double x) => w / 2 + (x - cx) * sx;
    double py(double y) => h / 2 - (y - cy) * sy;

    final xl = cx - w / (2 * sx);
    final xr = cx + w / (2 * sx);
    final yb = cy - h / (2 * sy);
    final yt = cy + h / (2 * sy);
    final stepX = niceStep(56 * s / sx);
    final stepY = niceStep(40 * s / sy);
    final axisY = py(0).clamp(0.0, h).toDouble();
    final axisX = px(0).clamp(0.0, w).toDouble();
    final grid = Paint()
      ..color = AppColors.grid
      ..strokeWidth = 1;

    for (var i = (xl / stepX).ceil(); i <= (xr / stepX).floor(); i++) {
      final v = i * stepX;
      final x = px(v);
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
      if (i != 0) {
        final flip = axisY > h - 18 * s;
        drawText(canvas, fmtTick(v, stepX),
            Offset(x, flip ? axisY - 12 * s : axisY + 12 * s),
            size: 11 * s, color: AppColors.muted);
      }
    }
    for (var j = (yb / stepY).ceil(); j <= (yt / stepY).floor(); j++) {
      final v = j * stepY;
      final y = py(v);
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
      if (j != 0) {
        drawText(canvas, fmtTick(v, stepY), Offset(4 * s, y),
            size: 11 * s, color: AppColors.muted, ax: 0);
      }
    }

    // axes with arrow heads
    final axis = Paint()
      ..color = Colors.white
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, axisY), Offset(w - 6 * s, axisY), axis);
    canvas.drawLine(Offset(axisX, h), Offset(axisX, 6 * s), axis);
    drawTriangle(canvas, Offset(w, axisY), const Offset(1, 0), 9 * s, Colors.white);
    drawTriangle(canvas, Offset(axisX, 0), const Offset(0, -1), 9 * s, Colors.white);

    final p = r.poly;
    final dom = r.domain;
    final dot = 5.5 * s;

    if (dom is SetDomain) {
      for (final x in dom.values) {
        final y = p.eval(x);
        final o = Offset(px(x.toDouble()), py(y.toDouble()));
        canvas.drawCircle(o, dot, Paint()..color = AppColors.accent);
        drawText(canvas, '$y', o + Offset(8 * s, -13 * s),
            size: 12 * s, color: AppColors.text, weight: FontWeight.w700, ax: 0);
      }
      return;
    }

    final d = dom as IntervalDomain;
    final lo = d.lo?.toDouble();
    final hi = d.hi?.toDouble();
    final x0 = lo == null ? xl : math.max(xl, lo);
    final x1 = hi == null ? xr : math.min(xr, hi);
    if (x1 >= x0) {
      final n = math.max(2, math.min(1500, (((x1 - x0) * sx) / 2).ceil()));
      final path = Path();
      for (var i = 0; i <= n; i++) {
        final x = x0 + (x1 - x0) * i / n;
        final yy = py(p.evalD(x)).clamp(-1e5, 1e5).toDouble();
        if (i == 0) {
          path.moveTo(px(x), yy);
        } else {
          path.lineTo(px(x), yy);
        }
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = AppColors.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8 * s
            ..strokeJoin = StrokeJoin.round);
    }

    void end(double? x, bool closed) {
      if (x == null) return;
      final o = Offset(px(x), py(p.evalD(x)));
      if (closed) {
        canvas.drawCircle(o, dot, Paint()..color = AppColors.accent);
      } else {
        canvas.drawCircle(o, dot, Paint()..color = _canvasBg);
        canvas.drawCircle(
            o,
            dot,
            Paint()
              ..color = AppColors.accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4 * s);
      }
    }

    end(lo, d.loClosed);
    end(hi, d.hiClosed);
  }

  @override
  bool shouldRepaint(covariant GraphPainter old) => true;
}
