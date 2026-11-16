import 'package:flutter/material.dart';
import 'theme.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * s),
      child: Center(
        child: Text(text,
            style: sans(12 * s,
                color: AppColors.muted, letterSpacing: 2.2 * s)),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    return Padding(
      padding: EdgeInsets.only(top: 14 * s, bottom: 6 * s),
      child: Text(text.toUpperCase(),
          style:
              sans(11 * s, color: AppColors.muted, letterSpacing: 1.6 * s)),
    );
  }
}

class DarkCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  const DarkCard({super.key, required this.child, this.borderColor});
  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10 * s),
      padding: EdgeInsets.all(14 * s),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final double height;
  final double fontSize;
  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.height = 46,
    this.fontSize = 14.5,
  });

  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    final r = BorderRadius.circular(14 * s);
    final enabled = onTap != null;
    return Material(
      color: selected ? AppColors.accent : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: r,
        side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: SizedBox(
          height: height * s,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * s),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: sans(fontSize * s,
                    color: selected
                        ? Colors.black
                        : (enabled ? AppColors.text : AppColors.muted)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text field tuned for watch keyboards (Samsung / Google): plain text mode,
/// no autocorrect, forced LTR so Persian keyboards cannot flip the math.
class MathField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const MathField({super.key, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    OutlineInputBorder b(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * s),
          borderSide: BorderSide(color: c),
        );
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      cursorColor: AppColors.accent,
      scrollPadding: EdgeInsets.all(60 * s),
      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: mono(15 * s),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.card,
        hintText: hint,
        hintStyle: mono(14 * s, color: AppColors.muted),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12 * s, vertical: 11 * s),
        border: b(AppColors.border),
        enabledBorder: b(AppColors.border),
        focusedBorder: b(AppColors.accent),
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  final bool filled;
  const LegendDot({super.key, required this.filled});
  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    return Container(
      width: 13 * s,
      height: 13 * s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.accent : Colors.transparent,
        border: Border.all(color: AppColors.accent, width: 2.2 * s),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Widget? icon;
  final String text;
  const LegendItem({super.key, this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[icon!, SizedBox(width: 6 * s)],
      Flexible(
        child: Text(text, style: sans(13 * s, color: AppColors.muted, weight: FontWeight.w500)),
      ),
    ]);
  }
}

/// "-  Fit  +" row used by the number line and the graph.
class ZoomRow extends StatelessWidget {
  final VoidCallback onMinus;
  final VoidCallback onFit;
  final VoidCallback onPlus;
  const ZoomRow(
      {super.key,
      required this.onMinus,
      required this.onFit,
      required this.onPlus});
  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    return Row(children: [
      Expanded(flex: 3, child: PillButton(label: '-', onTap: onMinus, fontSize: 18)),
      SizedBox(width: 8 * s),
      Expanded(flex: 4, child: PillButton(label: 'Fit', onTap: onFit, fontSize: 16)),
      SizedBox(width: 8 * s),
      Expanded(flex: 3, child: PillButton(label: '+', onTap: onPlus, fontSize: 18)),
    ]);
  }
}
