import 'expression.dart';
import 'models.dart';
import 'rational.dart';

export 'expression.dart' show ParseError;

// ───────────────────────── helpers ─────────────────────────

String _sup(int k) => k == 2 ? '²' : (k == 3 ? '³' : '^$k');

String _paren(Rational r) => (r.isNegative || !r.isInteger) ? '($r)' : '$r';

List<String> _dedupe(List<String> l) {
  final out = <String>[];
  for (final s in l) {
    if (out.isEmpty || out.last != s) out.add(s);
  }
  return out;
}

T _guard<T>(String label, T Function() f) {
  try {
    return f();
  } on ParseError catch (e) {
    throw ParseError('$label: ${e.message}');
  }
}

Rational _const(String raw, String label) =>
    _guard(label, () => parseConstant(raw, what: label));

List<String> _splitList(String raw) {
  final s = normalizeMath(raw).replaceAll('{', '').replaceAll('}', '');
  return s
      .split(RegExp(r'[,;\n]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

List<Rational> _parseList(String raw, String label) {
  final seen = <Rational>{};
  final out = <Rational>[];
  for (final t in _splitList(raw)) {
    final v = _const(t, label);
    if (seen.add(v)) out.add(v);
  }
  return out;
}

/// Splits "h(x) = 3x + a" into ('h', '3x + a').
(String, String) splitFunction(String raw) {
  final s = normalizeMath(raw).trim();
  final m = RegExp(r'^([A-Za-z])\s*\(\s*[xX]\s*\)\s*=(.*)$').firstMatch(s);
  if (m != null) return (m.group(1)!, m.group(2)!);
  if (s.contains('=')) {
    throw ParseError('Function: write it like f(x) = 4x^2 - 3x');
  }
  return ('f', s);
}

/// Cheap check used by the UI to decide whether to show the condition field.
bool functionUsesParam(String function) {
  try {
    final (_, body) = splitFunction(function);
    return body.toLowerCase().contains('a');
  } catch (_) {
    return false;
  }
}

// ───────────────────────── formatting ─────────────────────────

String formatPoly(NumPoly p) {
  final sb = StringBuffer();
  var first = true;
  for (final (c, k) in p.terms) {
    final ac = c.abs();
    String body;
    if (k == 0) {
      body = '$ac';
    } else {
      final xs = k == 1 ? 'x' : 'x${_sup(k)}';
      body = ac == Rational.one ? xs : '${ac.isInteger ? '$ac' : '($ac)'}$xs';
    }
    if (first) {
      sb.write(c.isNegative ? '-$body' : body);
      first = false;
    } else {
      sb.write(c.isNegative ? ' - $body' : ' + $body');
    }
  }
  return sb.toString();
}

String _join(List<(bool, String)> items) {
  final sb = StringBuffer();
  for (var i = 0; i < items.length; i++) {
    final (neg, body) = items[i];
    if (i == 0) {
      sb.write(neg ? '-$body' : body);
    } else {
      sb.write(neg ? ' - $body' : ' + $body');
    }
  }
  return sb.toString();
}

String _cpart(Rational c, int k) {
  final a = c.abs();
  if (k > 0 && a == Rational.one) return '';
  return a.isInteger ? '$a' : '($a)';
}

String _glue(String cp, String xp) =>
    cp.isEmpty ? xp : (xp.startsWith('(') ? '$cp$xp' : '$cp·$xp');

/// Step-by-step right-hand sides for p(x), e.g. for f = 4x² - 3x at -2:
///   4(-2)² - 3(-2) / 4·4 - 3(-2) / 16 - (-6) / 16 + 6 / 22
List<String> _evalLines(NumPoly p, Rational x) {
  final terms = p.terms;
  final l1 = <(bool, String)>[];
  final l2 = <(bool, String)>[];
  final l3 = <(bool, String)>[];
  final l4 = <(bool, String)>[];
  var hasPower = false;

  for (var i = 0; i < terms.length; i++) {
    final (c, k) = terms[i];
    final neg = c.isNegative;
    if (k == 0) {
      final s = '${c.abs()}';
      l1.add((neg, s));
      l2.add((neg, s));
    } else {
      final xp = k == 1 ? _paren(x) : '${_paren(x)}${_sup(k)}';
      final b1 = _glue(_cpart(c, k), xp);
      l1.add((neg, b1));
      if (k >= 2) {
        hasPower = true;
        l2.add((neg, _glue(_cpart(c, k), _paren(x.pow(k)))));
      } else {
        l2.add((neg, b1));
      }
    }
    final m = c.abs() * x.pow(k);
    l3.add((neg, (i == 0 && !neg) ? '$m' : _paren(m)));
    final v = c * x.pow(k);
    l4.add((v.isNegative, '${v.abs()}'));
  }

  return _dedupe([
    _join(l1),
    if (hasPower) _join(l2),
    _join(l3),
    _join(l4),
    '${p.eval(x)}',
  ]);
}

// ───────────────────────── parameter a ─────────────────────────

class _Cond {
  final Rational x;
  final Rational value;
  _Cond(this.x, this.value);
}

_Cond _parseCondition(String raw) {
  final s = normalizeMath(raw).trim();
  final parts = s.split('=');
  const hint = 'Condition: write it like h(1) = 2';
  if (parts.length != 2) throw ParseError(hint);
  final m = RegExp(r'^[A-Za-z]\s*\((.*)\)$').firstMatch(parts[0].trim());
  if (m == null) throw ParseError(hint);
  return _Cond(_const(m.group(1)!, 'Condition x'),
      _const(parts[1], 'Condition value'));
}

List<String> _paramSteps(String name, NumPoly pk, _Cond cond, Rational kv,
    Rational mv, Rational a) {
  String coefMul(Rational m) {
    if (m == Rational.one) return '';
    if (m == -Rational.one) return '-';
    return m.isInteger ? '$m·' : '($m)·';
  }

  String aTerm(Rational m) {
    final mag = m.abs();
    final c = mag == Rational.one
        ? ''
        : (mag.isInteger ? '$mag·' : '($mag)·');
    return '${m.isNegative ? '-' : '+'} ${c}a';
  }

  final val = cond.value;
  final lines = <String>[
    '$name(${cond.x}) = $val',
    '${_evalLines(pk, cond.x).first} ${aTerm(mv)} = $val',
    '$kv ${aTerm(mv)} = $val',
  ];
  final diff = val - kv;
  if (kv.isZero) {
    if (mv == Rational.one) {
      lines.add('a = $val');
    } else {
      lines.add('${coefMul(mv)}a = $val');
      lines.add('a = $val / ${_paren(mv)}');
    }
  } else if (mv == Rational.one) {
    lines.add('a = $val - ${_paren(kv)}');
  } else {
    lines.add('${coefMul(mv)}a = $val - ${_paren(kv)}');
    lines.add('${coefMul(mv)}a = $diff');
    lines.add('a = $diff / ${_paren(mv)}');
  }
  lines.add('a = $a');
  return _dedupe(lines);
}

// ───────────────────────── range ─────────────────────────

RangeInfo computeRange(NumPoly p, Domain dom) {
  if (dom is SetDomain) {
    final ys = <Rational>{for (final x in dom.values) p.eval(x)}.toList()
      ..sort((a, b) => a.compareTo(b));
    return RangeInfo.discrete(ys);
  }
  final d = dom as IntervalDomain;
  final lo = d.lo;
  final hi = d.hi;

  if (lo != null && hi != null && lo == hi) {
    final y = p.eval(lo);
    return RangeInfo.interval(lo: y, hi: y, loClosed: true, hiClosed: true);
  }

  if (p.c2.isZero) {
    if (p.c1.isZero) {
      return RangeInfo.interval(
          lo: p.c0, hi: p.c0, loClosed: true, hiClosed: true);
    }
    Rational? lowV;
    Rational? highV;
    bool lowC;
    bool highC;
    if (p.c1.isPositive) {
      lowV = lo == null ? null : p.eval(lo);
      lowC = lo != null && d.loClosed;
      highV = hi == null ? null : p.eval(hi);
      highC = hi != null && d.hiClosed;
    } else {
      lowV = hi == null ? null : p.eval(hi);
      lowC = hi != null && d.hiClosed;
      highV = lo == null ? null : p.eval(lo);
      highC = lo != null && d.loClosed;
    }
    return RangeInfo.interval(
        lo: lowV, hi: highV, loClosed: lowC, hiClosed: highC);
  }

  // Quadratic. Work with a convex q (c2 > 0); flip at the end when c2 < 0.
  final neg = p.c2.isNegative;
  final q = neg ? -p : p;
  final xv = -q.c1 / (Rational.two * q.c2);
  final yv = q.eval(xv);

  Rational minV;
  bool minC;
  if (d.contains(xv)) {
    minV = yv;
    minC = true;
  } else if (lo != null && xv <= lo) {
    minV = q.eval(lo);
    minC = d.loClosed;
  } else {
    minV = q.eval(hi!);
    minC = d.hiClosed;
  }

  Rational? maxV; // null = +infinity
  var maxC = false;
  if (lo != null && hi != null) {
    final ql = q.eval(lo);
    final qh = q.eval(hi);
    final c = ql.compareTo(qh);
    if (c > 0) {
      maxV = ql;
      maxC = d.loClosed;
    } else if (c < 0) {
      maxV = qh;
      maxC = d.hiClosed;
    } else {
      maxV = ql;
      maxC = d.loClosed || d.hiClosed;
    }
  }

  if (!neg) {
    return RangeInfo.interval(
        lo: minV, hi: maxV, loClosed: minC, hiClosed: maxC);
  }
  return RangeInfo.interval(
      lo: maxV == null ? null : -maxV,
      hi: -minV,
      loClosed: maxC,
      hiClosed: minC);
}

// ───────────────────────── key points ─────────────────────────

List<KeyRow> _keyRows(NumPoly p, Domain dom) {
  if (dom is SetDomain) {
    return [for (final x in dom.values) KeyRow('$x', 'point', '${p.eval(x)}')];
  }
  final d = dom as IntervalDomain;
  final entries = <Rational, (String, bool)>{}; // x -> (tag, isOpenEnd)
  Rational? xv;
  if (p.isQuadratic) {
    xv = -p.c1 / (Rational.two * p.c2);
    if (d.contains(xv)) entries[xv] = ('vertex', false);
  }
  void addEnd(Rational? x, bool closed) {
    if (x == null || entries.containsKey(x)) return;
    entries[x] = (closed ? 'endpoint' : 'open end', !closed);
  }

  addEnd(d.lo, d.loClosed);
  addEnd(d.hi, d.hiClosed);

  if (entries.length < 5) {
    final lo = d.lo;
    final hi = d.hi;
    Rational base;
    if (lo != null && hi != null) {
      base = Rational(((lo + hi) / Rational.two).floor());
    } else if (xv != null) {
      base = Rational(xv.floor());
    } else if (lo != null) {
      base = Rational(lo.floor());
    } else if (hi != null) {
      base = Rational(hi.floor());
    } else {
      base = Rational.zero;
    }
    for (var step = 0; step <= 60 && entries.length < 6; step++) {
      final offs = step == 0 ? [0] : [step, -step];
      for (final off in offs) {
        final x = base + Rational.fromInt(off);
        if (entries.length < 6 && d.contains(x) && !entries.containsKey(x)) {
          entries[x] = ('sample', false);
        }
      }
    }
  }

  final xs = entries.keys.toList()..sort((a, b) => a.compareTo(b));
  return [
    for (final x in xs)
      entries[x]!.$2
          ? KeyRow('$x', entries[x]!.$1, '→${p.eval(x)}', muted: true)
          : KeyRow('$x', entries[x]!.$1, '${p.eval(x)}'),
  ];
}

// ───────────────────────── main entry ─────────────────────────

AnalysisResult analyze(InputData d) {
  if (d.function.trim().isEmpty) {
    throw ParseError('Enter a function, e.g. f(x) = 4x^2 - 3x');
  }
  final (name, body) = splitFunction(d.function);
  final poly = _guard('Function', () => parsePolynomial(body));
  if (poly.degree > 2) {
    throw ParseError('Function: only linear and quadratic (degree ≤ 2).');
  }

  // Domain
  final Domain domain;
  if (d.mode == DomainMode.interval) {
    Rational? lo;
    Rational? hi;
    if (!d.leftInf) lo = _const(d.leftText, 'Left bound');
    if (!d.rightInf) hi = _const(d.rightText, 'Right bound');
    final lc = lo != null && d.leftClosed;
    final rc = hi != null && d.rightClosed;
    if (lo != null && hi != null) {
      final c = lo.compareTo(hi);
      if (c > 0) {
        throw ParseError('Left bound must not exceed the right bound.');
      }
      if (c == 0 && !(lc && rc)) {
        throw ParseError('Empty interval. Use [a, a] for a single point.');
      }
    }
    domain = IntervalDomain(lo: lo, hi: hi, loClosed: lc, hiClosed: rc);
  } else {
    final vals = _parseList(d.setText, 'Set');
    if (vals.isEmpty) throw ParseError('Set: enter at least one number.');
    vals.sort((a, b) => a.compareTo(b));
    domain = SetDomain(vals);
  }

  final queries = _parseList(d.queryText, 'Query');

  // Unknown constant a
  Rational? aVal;
  var paramLines = <String>[];
  if (poly.hasParam) {
    if (d.condition.trim().isEmpty) {
      throw ParseError('Enter a condition like $name(1) = 2 to find a.');
    }
    final cond = _parseCondition(d.condition);
    if (!domain.contains(cond.x)) {
      throw ParseError('Condition: ${cond.x} is outside the domain.');
    }
    final pk = NumPoly(poly.coef(0).k, poly.coef(1).k, poly.coef(2).k);
    final pa = NumPoly(poly.coef(0).m, poly.coef(1).m, poly.coef(2).m);
    final kv = pk.eval(cond.x);
    final mv = pa.eval(cond.x);
    if (mv.isZero) {
      throw ParseError(kv == cond.value
          ? 'Condition: it holds for every a, so a is undetermined.'
          : 'Condition: no value of a satisfies it.');
    }
    aVal = (cond.value - kv) / mv;
    paramLines = _paramSteps(name, pk, cond, kv, mv, aVal);
  }

  final av = aVal ?? Rational.zero;
  Rational pick(int k) {
    final l = poly.coef(k);
    return l.k + l.m * av;
  }

  final np = NumPoly(pick(0), pick(1), pick(2));

  final evals = <QueryEval>[
    for (final q in queries)
      domain.contains(q)
          ? QueryEval(
              x: q,
              inDomain: true,
              head: '$name($q)',
              lines: _evalLines(np, q),
              value: np.eval(q))
          : QueryEval(
              x: q,
              inDomain: false,
              head: '$name($q)',
              lines: const [],
              value: null),
  ];

  return AnalysisResult(
    name: name,
    funcText: '$name(x) = ${formatPoly(np)}',
    poly: np,
    domain: domain,
    range: computeRange(np, domain),
    paramLines: paramLines,
    paramValue: aVal,
    queries: evals,
    keyRows: _keyRows(np, domain),
  );
}
