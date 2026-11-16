import 'package:flutter/material.dart';
import '../core/models.dart';
import 'theme.dart';
import 'widgets.dart';

class StepsPage extends StatelessWidget {
  final AnalysisResult r;
  const StepsPage({super.key, required this.r});

  Widget _line(double s, String t, {Color color = AppColors.text}) => Padding(
        padding: EdgeInsets.only(bottom: 2 * s),
        child: Text(t, style: mono(14 * s, color: color)),
      );

  Widget _labeled(double s, String label, String rest) => Padding(
        padding: EdgeInsets.only(bottom: 2 * s),
        child: Text.rich(TextSpan(style: mono(14 * s), children: [
          TextSpan(
              text: label,
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          TextSpan(text: ' = $rest'),
        ])),
      );

  Widget _evalCard(double s, QueryEval q) {
    if (!q.inDomain) {
      return DarkCard(
        borderColor: AppColors.accent,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(q.head, style: mono(16 * s, weight: FontWeight.w700)),
          SizedBox(height: 4 * s),
          Text('Undefined (Outside Domain)',
              style: sans(15.5 * s, color: AppColors.accent, weight: FontWeight.w800)),
          SizedBox(height: 2 * s),
          Text('${q.x} ∉ Df = ${r.domain.notation}',
              style: sans(13.5 * s, color: AppColors.muted, weight: FontWeight.w500)),
        ]),
      );
    }
    final pad = ' ' * (q.head.length + 1);
    final spans = <InlineSpan>[
      TextSpan(text: q.head, style: const TextStyle(color: AppColors.accent)),
      TextSpan(text: ' = ${q.lines.first}'),
    ];
    for (final l in q.lines.skip(1)) {
      spans.add(TextSpan(text: '\n$pad= $l'));
    }
    return DarkCard(
      child: Text.rich(TextSpan(style: mono(13.5 * s), children: spans)),
    );
  }

  Widget _paramCard(double s) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < r.paramLines.length; i++) {
      final last = i == r.paramLines.length - 1;
      spans.add(TextSpan(
        text: (i == 0 ? '' : '\n') + r.paramLines[i],
        style: last
            ? const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)
            : null,
      ));
    }
    return DarkCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Solve a', style: mono(15 * s, weight: FontWeight.w700)),
        SizedBox(height: 6 * s),
        Text.rich(TextSpan(style: mono(13.5 * s), children: spans)),
      ]),
    );
  }

  Widget _keyPoints(double s) {
    Widget row(Widget left, String y, {bool muted = false, bool last = false}) =>
        Container(
          padding: EdgeInsets.symmetric(vertical: 7 * s),
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: AppColors.border),
              bottom: last
                  ? const BorderSide(color: AppColors.border)
                  : BorderSide.none,
            ),
          ),
          child: Row(children: [
            Expanded(child: left),
            Text(y,
                style: mono(14 * s,
                    color: muted ? AppColors.muted : AppColors.text,
                    weight: FontWeight.w600)),
          ]),
        );

    return DarkCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Key points', style: mono(16 * s, weight: FontWeight.w700)),
        SizedBox(height: 8 * s),
        Row(children: [
          Expanded(child: Text('X', style: mono(12 * s, color: AppColors.muted))),
          Text('Y', style: mono(12 * s, color: AppColors.muted)),
        ]),
        SizedBox(height: 6 * s),
        for (var i = 0; i < r.keyRows.length; i++)
          row(
            Text.rich(TextSpan(style: mono(14 * s), children: [
              TextSpan(text: r.keyRows[i].x),
              TextSpan(
                  text: '  ${r.keyRows[i].tag}',
                  style: mono(11.5 * s, color: AppColors.muted)),
            ])),
            r.keyRows[i].y,
            muted: r.keyRows[i].muted,
            last: i == r.keyRows.length - 1,
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    final dom = r.domain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('STEPS'),
        _line(s, r.funcText),
        _labeled(s, 'Df', dom.notation),
        _line(s, dom.typeLabel),
        if (dom is IntervalDomain) _line(s, dom.setBuilder, color: AppColors.muted),
        _labeled(s, 'Rf', r.range.notation),
        _line(s, 'bounds ${r.range.bounds}'),
        SizedBox(height: 12 * s),
        if (r.paramLines.isNotEmpty) _paramCard(s),
        if (r.queries.isEmpty)
          _line(s, 'No query points.', color: AppColors.muted)
        else
          for (final q in r.queries) _evalCard(s, q),
        _keyPoints(s),
      ],
    );
  }
}
