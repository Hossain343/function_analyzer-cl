import 'package:flutter/material.dart';
import '../core/models.dart';
import 'app_controller.dart';
import 'theme.dart';
import 'widgets.dart';

class InputPage extends StatelessWidget {
  final AppController c;
  const InputPage({super.key, required this.c});

  Widget _boundRow(BuildContext context, {required bool isLeft}) {
    final s = Dim.of(context).s;
    final closed = isLeft ? c.leftClosed : c.rightClosed;
    final inf = isLeft ? c.leftInf : c.rightInf;
    final label = isLeft ? (closed ? '[' : '(') : (closed ? ']' : ')');

    final bracket = SizedBox(
      width: 44 * s,
      child: PillButton(
        label: label,
        height: 44,
        fontSize: 17,
        selected: closed && !inf,
        onTap: inf ? null : (isLeft ? c.toggleLeftClosed : c.toggleRightClosed),
      ),
    );
    final infBtn = SizedBox(
      width: 44 * s,
      child: PillButton(
        label: '∞',
        height: 44,
        fontSize: 18,
        selected: inf,
        onTap: isLeft ? c.toggleLeftInf : c.toggleRightInf,
      ),
    );
    final Widget field = inf
        ? Container(
            height: 44 * s,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 12 * s),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12 * s),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(isLeft ? '-∞' : '∞',
                style: mono(15 * s, color: AppColors.muted)),
          )
        : MathField(
            controller: isLeft ? c.left : c.right,
            hint: 'number',
          );
    final gap = SizedBox(width: 8 * s);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isLeft
          ? [bracket, gap, Expanded(child: field), gap, infBtn]
          : [infBtn, gap, Expanded(child: field), gap, bracket],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    final r = c.result;
    final gap = SizedBox(width: 8 * s);
    final vgap = SizedBox(height: 8 * s);

    Widget preset(int i, String label) => Expanded(
          child: PillButton(label: label, onTap: () => c.loadPreset(i)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('INPUT'),
        const FieldLabel('Function'),
        MathField(controller: c.function, hint: 'f(x) = 4x^2 - 3x'),
        const FieldLabel('Domain'),
        Row(children: [
          Expanded(
            child: PillButton(
              label: 'Interval',
              selected: c.mode == DomainMode.interval,
              onTap: () => c.setMode(DomainMode.interval),
            ),
          ),
          gap,
          Expanded(
            child: PillButton(
              label: 'Set',
              selected: c.mode == DomainMode.discrete,
              onTap: () => c.setMode(DomainMode.discrete),
            ),
          ),
        ]),
        if (c.mode == DomainMode.interval) ...[
          const FieldLabel('Left bound'),
          _boundRow(context, isLeft: true),
          const FieldLabel('Right bound'),
          _boundRow(context, isLeft: false),
        ] else ...[
          const FieldLabel('Discrete set'),
          MathField(controller: c.setText, hint: '-2, 0, 1, 2, 4'),
        ],
        const FieldLabel('Query points'),
        MathField(controller: c.query, hint: '-2, 1, 5'),
        if (c.needsCondition) ...[
          const FieldLabel('Condition'),
          MathField(controller: c.condition, hint: 'h(1) = 2'),
        ],
        SizedBox(height: 12 * s),
        Container(
          key: c.statusKey,
          child: c.error != null
              ? Text(c.error!,
                  style: mono(12.5 * s, color: AppColors.danger))
              : (r == null
                  ? const SizedBox.shrink()
                  : Text('${r.funcText} · Rf = ${r.range.notation}',
                      style: mono(12.5 * s, color: AppColors.muted))),
        ),
        SizedBox(height: 12 * s),
        Row(children: [preset(0, 'Quadratic'), gap, preset(1, 'Solve a')]),
        vgap,
        Row(children: [preset(2, 'Discrete'), gap, preset(3, 'Half-open')]),
      ],
    );
  }
}
