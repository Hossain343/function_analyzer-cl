import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF07080A);
  static const card = Color(0xFF141519);
  static const border = Color(0xFF272A30);
  static const accent = Color(0xFFF2A200);
  static const text = Color(0xFFF2F2F4);
  static const muted = Color(0xFF9EA0A8);
  static const danger = Color(0xFFFF6B5E);
  static const grid = Color(0xFF1E2025);
}

/// Screen diameter (min side) and a scale factor relative to a 384 dp watch.
class Dim extends InheritedWidget {
  final double d;
  const Dim({super.key, required this.d, required super.child});

  double get s => (d / 384).clamp(0.7, 2.2).toDouble();

  static Dim of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Dim>()!;

  @override
  bool updateShouldNotify(Dim old) => old.d != d;
}

TextStyle mono(double size,
        {Color color = AppColors.text,
        FontWeight weight = FontWeight.w500,
        double height = 1.35}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Consolas', 'Roboto Mono', 'Courier New'],
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
    );

TextStyle sans(double size,
        {Color color = AppColors.text,
        FontWeight weight = FontWeight.w700,
        double letterSpacing = 0}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
