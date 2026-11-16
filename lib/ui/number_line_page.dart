import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/rational.dart';
import 'chart_utils.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Kind { setPoint, closedEnd, openEnd, inQuery, outQuery }

class _Mark {
  final Rational x;
  final _Kind kind;
  final String info;
  const _Mark(this.x, this.kind, this.info);
  double get xd => x.toDouble();
}

const _canvasBg = Color(0xFF0B0C0F);
const _baseCol = Color(0xFF3A3D44);
const _mutedMark = Color(0xFF8B8E96);

class NumberLinePage extends StatefulWidget {
  final AnalysisResult r;
  const NumberLinePage({super.key, required this.r});
  @override
  State<NumberLinePage> createState() => _NumberLinePageState();
}

class _NumberLinePageState extends State<NumberLinePage> {
  late final List<_Mark> marks = _build(widget.r);
  double _cx = 0;
  double _scale = 40;
  double _w = 300;
  bool _needFit = true;
  int _sel = -1;

  static List<_Mark> _build(AnalysisResult r) {
    final p = r.poly;
    final n = r.name;
    final dom = r.domain;
    final out = <_Mark>[];
    if (dom is SetDomain) {
      for (final x in dom.values) {
        out.add(_Mark(x, _Kind.setPoint, '$n($x) = ${p.eval(x)}'));
      }
    } else if (dom is IntervalDomain) {
      void end(Rational? x, bool closed) {
        if (x == null) return;
        out.add(closed
            ? _Mark(x, _Kind.closedEnd, '$n($x) = ${p.eval(x)}')
            : _Mark(x, _Kind.openEnd, '$x ∉ Df · open end'));
      }

      end(dom.lo, dom.loClosed);
      end(dom.hi, dom.hiClosed);
    }
    for (final q in r.queries) {
      if (out.any((m) => m.x == q.x)) continue;
      if (q.inDomain) {
        out.add(_Mark(q.x, _Kind.inQuery, '$n(${q.x}) = ${q.value}'));
      } else {
        out.add(_Mark(q.x, _Kind.outQuery, '${q.x} ∉ Df'));
      }
    }
    return out;
  }

  void _fit() {
    final dom = widget.r.domain;
    double a;
    double b;
    if (marks.isEmpty) {
      a = -5;
      b = 5;
    } else {
      final xs = marks.map((m) => m.xd).toList();
      a = xs.reduce(math.min);
      b = xs.reduce(math.max);
    }
    if (b - a < 1e-9) {
      a -= 2;
      b += 2;
    }
    var padL = (b - a) * 0.14;
    var padR = padL;
    if (dom is IntervalDomain) {
      if (dom.lo == null) padL = (b - a) * 0.3;
      if (dom.hi == null) padR = (b - a) * 0.3;
    }
    a -= padL;
    b += padR;
    _cx = (a + b) / 2;
    _scale = math.max(1e-6, _w / (b - a));
  }

  void _tap(Offset p, double h, double s) {
    var best = -1;
    var bd = 24 * s;
    for (var i = 0; i < marks.length; i++) {
      final sx = _w / 2 + (marks[i].xd - _cx) * _scale;
      final dx = (sx - p.dx).abs();
      if (dx < bd && (p.dy - h * 0.55).abs() < h * 0.4) {
        bd = dx;
        best = i;
      }
    }
    setState(() => _sel = best);
  }

  @override
  Widget build(BuildContext context) {
    final dim = Dim.of(context);
    final s = dim.s;
    final dom = widget.r.domain;
    final canvasH = dim.d * 0.36;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('NUMBER LINE'),
        Text.rich(TextSpan(style: mono(14 * s), children: [
          const TextSpan(
              text: 'Df',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          TextSpan(text: ' = ${dom.notation}'),
        ])),
        Text(dom is IntervalDomain ? 'Interval notation' : 'Roster notation',
            style: mono(14 * s)),
        if (dom is IntervalDomain)
          Text(dom.setBuilder, style: mono(13 * s, color: AppColors.muted)),
        SizedBox(height: 10 * s),
        LayoutBuilder(builder: (context, box) {
          _w = box.maxWidth;
          if (_needFit) {
            _fit();
            _needFit = false;
          }
          return GestureDetector(
            onHorizontalDragUpdate: (d) =>
                setState(() => _cx -= d.delta.dx / _scale),
            onTapUp: (d) => _tap(d.localPosition, canvasH, s),
            child: Container(
              height: canvasH,
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
                  painter: NumberLinePainter(
                      r: widget.r, marks: marks, cx: _cx, scale: _scale, sel: _sel, s: s),
                ),
              ),
            ),
          );
        }),
        SizedBox(height: 10 * s),
        Text(_sel >= 0 ? marks[_sel].info : 'Drag to pan. Tap a mark.',
            style: mono(13.5 * s)),
        SizedBox(height: 10 * s),
        ZoomRow(
          onMinus: () => setState(() => _scale /= 1.4),
          onPlus: () => setState(() => _scale *= 1.4),
          onFit: () => setState(() {
            _fit();
            _sel = -1;
          }),
        ),
        SizedBox(height: 12 * s),
        Wrap(spacing: 16 * s, runSpacing: 8 * s, children: [
          if (dom is IntervalDomain) ...[
            const LegendItem(icon: LegendDot(filled: true), text: 'Closed'),
            const LegendItem(icon: LegendDot(filled: false), text: 'Open'),
          ] else
            const LegendItem(icon: LegendDot(filled: true), text: 'Included'),
          const LegendItem(text: 'Muted cross = outside query'),
        ]),
      ],
    );
  }
}

class NumberLinePainter extends CustomPainter {
  final AnalysisResult r;
  final List<_Mark> marks;
  final double cx;
  final double scale;
  final int sel;
  final double s;
  NumberLinePainter({
    required this.r,
    required this.marks,
    required this.cx,
    required this.scale,
    required this.sel,
    required this.s,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final by = h * 0.55;
    double px(double x) => w / 2 + (x - cx) * scale;

    // base line + arrows
    canvas.drawLine(Offset(14 * s, by), Offset(w - 14 * s, by),
        Paint()..color = _baseCol..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
    drawTriangle(canvas, Offset(6 * s, by), const Offset(-1, 0), 11 * s, _mutedMark);
    drawTriangle(canvas, Offset(w - 6 * s, by), const Offset(1, 0), 11 * s, _mutedMark);

    // ticks
    final step = niceStep(46 * s / scale);
    final xl = cx - w / (2 * scale);
    final xr = cx + w / (2 * scale);
    final tickPaint = Paint()..color = _mutedMark..strokeWidth = 1.5 * s;
    for (var i = (xl / step).ceil(); i <= (xr / step).floor(); i++) {
      final x = px(i * step);
      if (x < 24 * s || x > w - 24 * s) continue;
      canvas.drawLine(Offset(x, by - 4 * s), Offset(x, by + 4 * s), tickPaint);
      drawText(canvas, fmtTick(i * step, step), Offset(x, by + 20 * s),
          size: 12 * s, color: AppColors.muted);
    }

    // interval segment
    final dom = r.domain;
    if (dom is IntervalDomain) {
      final lo = dom.lo;
      final hi = dom.hi;
      final a = lo == null ? 10 * s : px(lo.toDouble());
      final b = hi == null ? w - 10 * s : px(hi.toDouble());
      final left = math.max(a, -50.0);
      final right = math.min(b, w + 50);
      if (right > left) {
        canvas.drawLine(Offset(left, by), Offset(right, by),
            Paint()..color = AppColors.accent..strokeWidth = 6 * s);
      }
      if (lo == null) {
        drawTriangle(canvas, Offset(4 * s, by), const Offset(-1, 0), 11 * s, AppColors.accent);
      }
      if (hi == null) {
        drawTriangle(canvas, Offset(w - 4 * s, by), const Offset(1, 0), 11 * s, AppColors.accent);
      }
    }

    // marks
    for (var i = 0; i < marks.length; i++) {
      final m = marks[i];
      final x = px(m.xd);
      if (x < -20 || x > w + 20) continue;
      final o = Offset(x, by);
      Color labelColor = AppColors.accent;
      switch (m.kind) {
        case _Kind.setPoint:
        case _Kind.closedEnd:
          canvas.drawCircle(o, 7 * s, Paint()..color = AppColors.accent);
          break;
        case _Kind.openEnd:
          canvas.drawCircle(o, 7 * s, Paint()..color = _canvasBg);
          canvas.drawCircle(
              o,
              7 * s,
              Paint()
                ..color = AppColors.accent
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.6 * s);
          break;
        case _Kind.inQuery:
          canvas.drawCircle(o, 4.5 * s, Paint()..color = AppColors.text);
          labelColor = AppColors.text;
          break;
        case _Kind.outQuery:
          final p = Paint()
            ..color = _mutedMark
            ..strokeWidth = 2.6 * s
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(o + Offset(-6 * s, -6 * s), o + Offset(6 * s, 6 * s), p);
          canvas.drawLine(o + Offset(-6 * s, 6 * s), o + Offset(6 * s, -6 * s), p);
          labelColor = _mutedMark;
          break;
      }
      drawText(canvas, '${m.x}', Offset(x, by - 24 * s),
          size: 12.5 * s, color: labelColor, weight: FontWeight.w700);
      if (i == sel) {
        canvas.drawCircle(
            o,
            13 * s,
            Paint()
              ..color = AppColors.text
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6 * s);
      }
    }
  }

  @override
  bool shouldRepaint(covariant NumberLinePainter old) => true;
}
