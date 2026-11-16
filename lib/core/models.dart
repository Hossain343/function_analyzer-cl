import 'rational.dart';

enum DomainMode { interval, discrete }

class InputData {
  final String function;
  final String condition;
  final DomainMode mode;
  final String leftText;
  final String rightText;
  final bool leftClosed;
  final bool rightClosed;
  final bool leftInf;
  final bool rightInf;
  final String setText;
  final String queryText;

  const InputData({
    required this.function,
    this.condition = '',
    required this.mode,
    this.leftText = '',
    this.rightText = '',
    this.leftClosed = true,
    this.rightClosed = true,
    this.leftInf = false,
    this.rightInf = false,
    this.setText = '',
    this.queryText = '',
  });
}

/// Polynomial of degree <= 2 with exact coefficients: c2*x^2 + c1*x + c0.
class NumPoly {
  final Rational c0;
  final Rational c1;
  final Rational c2;
  const NumPoly(this.c0, this.c1, this.c2);

  Rational coef(int k) => k == 2 ? c2 : (k == 1 ? c1 : c0);
  bool get isQuadratic => !c2.isZero;

  Rational eval(Rational x) => (c2 * x + c1) * x + c0;
  double evalD(double x) =>
      (c2.toDouble() * x + c1.toDouble()) * x + c0.toDouble();

  NumPoly operator -() => NumPoly(-c0, -c1, -c2);

  /// Non-zero terms, highest power first. A zero polynomial gives [(0, 0)].
  List<(Rational, int)> get terms {
    final t = <(Rational, int)>[];
    for (final k in [2, 1, 0]) {
      if (!coef(k).isZero) t.add((coef(k), k));
    }
    if (t.isEmpty) t.add((Rational.zero, 0));
    return t;
  }
}

sealed class Domain {
  const Domain();
  bool contains(Rational x);
  String get notation;
  String get typeLabel;
}

class IntervalDomain extends Domain {
  final Rational? lo;
  final Rational? hi;
  final bool loClosed;
  final bool hiClosed;
  const IntervalDomain({
    this.lo,
    this.hi,
    this.loClosed = false,
    this.hiClosed = false,
  });

  @override
  bool contains(Rational x) {
    final l = lo;
    final h = hi;
    if (l != null) {
      final c = x.compareTo(l);
      if (c < 0 || (c == 0 && !loClosed)) return false;
    }
    if (h != null) {
      final c = x.compareTo(h);
      if (c > 0 || (c == 0 && !hiClosed)) return false;
    }
    return true;
  }

  @override
  String get notation {
    final l = lo == null ? '-∞' : '$lo';
    final r = hi == null ? '∞' : '$hi';
    return '${loClosed ? '[' : '('}$l, $r${hiClosed ? ']' : ')'}';
  }

  String get setBuilder {
    final l = lo;
    final h = hi;
    if (l == null && h == null) return '{x ∈ R}';
    if (l != null && h != null && l == h) return '{x ∈ R | x = $l}';
    if (l == null) return '{x ∈ R | x ${hiClosed ? '≤' : '<'} $h}';
    if (h == null) return '{x ∈ R | x ${loClosed ? '≥' : '>'} $l}';
    return '{x ∈ R | $l ${loClosed ? '≤' : '<'} x ${hiClosed ? '≤' : '<'} $h}';
  }

  @override
  String get typeLabel => 'Interval';
}

class SetDomain extends Domain {
  final List<Rational> values; // sorted, distinct
  const SetDomain(this.values);

  @override
  bool contains(Rational x) => values.contains(x);

  @override
  String get notation => '{${values.join(', ')}}';

  @override
  String get typeLabel => 'Discrete set';
}

class RangeInfo {
  final bool isSet;
  final List<Rational> values; // when isSet
  final Rational? lo; // null = infinite (interval)
  final Rational? hi;
  final bool loClosed;
  final bool hiClosed;

  const RangeInfo.discrete(this.values)
      : isSet = true,
        lo = null,
        hi = null,
        loClosed = false,
        hiClosed = false;

  const RangeInfo.interval({
    this.lo,
    this.hi,
    this.loClosed = false,
    this.hiClosed = false,
  })  : isSet = false,
        values = const [];

  bool get isSingleton {
    final l = lo;
    final h = hi;
    return !isSet && l != null && h != null && l == h;
  }

  String get notation {
    if (isSet) return '{${values.join(', ')}}';
    if (isSingleton) return '{$lo}';
    final l = lo == null ? '-∞' : '$lo';
    final r = hi == null ? '∞' : '$hi';
    return '${loClosed ? '[' : '('}$l, $r${hiClosed ? ']' : ')'}';
  }

  String get bounds {
    if (isSet) return '${values.first} … ${values.last}';
    return '${lo ?? '-∞'} … ${hi ?? '∞'}';
  }
}

class QueryEval {
  final Rational x;
  final bool inDomain;
  final String head; // e.g. f(-2)
  final List<String> lines; // right-hand sides, last one is the value
  final Rational? value;
  const QueryEval({
    required this.x,
    required this.inDomain,
    required this.head,
    required this.lines,
    required this.value,
  });
}

class KeyRow {
  final String x;
  final String tag;
  final String y;
  final bool muted;
  const KeyRow(this.x, this.tag, this.y, {this.muted = false});
}

class AnalysisResult {
  final String name;
  final String funcText;
  final NumPoly poly;
  final Domain domain;
  final RangeInfo range;
  final List<String> paramLines;
  final Rational? paramValue;
  final List<QueryEval> queries;
  final List<KeyRow> keyRows;

  const AnalysisResult({
    required this.name,
    required this.funcText,
    required this.poly,
    required this.domain,
    required this.range,
    required this.paramLines,
    required this.paramValue,
    required this.queries,
    required this.keyRows,
  });
}
