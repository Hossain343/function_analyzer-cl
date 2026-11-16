import 'rational.dart';

class ParseError implements Exception {
  final String message;
  ParseError(this.message);
  @override
  String toString() => message;
}

/// Converts keyboard variants (Persian/Arabic digits, unicode minus, ², ·, ...)
/// into plain ASCII math so any watch keyboard works.
String normalizeMath(String input) {
  const map = <String, String>{
    '−': '-', '–': '-', '—': '-', '‒': '-',
    '×': '*', '·': '*', '∙': '*', '⋅': '*', '•': '*',
    '÷': '/', '∕': '/', '⁄': '/',
    '²': '^2', '³': '^3',
    '٫': '.', '،': ',', '؛': ';',
    '＋': '+', '＝': '=', '（': '(', '）': ')',
  };
  final b = StringBuffer();
  for (final r in input.runes) {
    if (r >= 0x660 && r <= 0x669) {
      b.write(r - 0x660);
    } else if (r >= 0x6F0 && r <= 0x6F9) {
      b.write(r - 0x6F0);
    } else {
      final ch = String.fromCharCode(r);
      b.write(map[ch] ?? ch);
    }
  }
  return b.toString();
}

/// Coefficient of the form k + m*a (a = the unknown parameter).
class Lin {
  final Rational k;
  final Rational m;
  const Lin(this.k, this.m);

  static final Lin zero = Lin(Rational.zero, Rational.zero);
  factory Lin.constant(Rational v) => Lin(v, Rational.zero);

  bool get isZero => k.isZero && m.isZero;
  bool get hasParam => !m.isZero;

  Lin operator +(Lin o) => Lin(k + o.k, m + o.m);
  Lin operator -(Lin o) => Lin(k - o.k, m - o.m);
  Lin operator -() => Lin(-k, -m);
  Lin operator *(Lin o) {
    if (!m.isZero && !o.m.isZero) {
      throw ParseError('The parameter a may only appear to the first power.');
    }
    return Lin(k * o.k, k * o.m + m * o.k);
  }
}

/// Polynomial in x whose coefficients may contain the parameter a (linearly).
class Poly {
  final Map<int, Lin> c;
  Poly(Map<int, Lin> m)
      : c = {
          for (final e in m.entries)
            if (!e.value.isZero) e.key: e.value
        };

  factory Poly.constant(Rational v) =>
      Poly(v.isZero ? {} : {0: Lin.constant(v)});
  factory Poly.x() => Poly({1: Lin.constant(Rational.one)});
  factory Poly.param() => Poly({0: Lin(Rational.zero, Rational.one)});

  Lin coef(int k) => c[k] ?? Lin.zero;
  int get degree => c.isEmpty ? 0 : c.keys.reduce((a, b) => a > b ? a : b);
  bool get hasParam => c.values.any((l) => l.hasParam);
  bool get isConstant => c.keys.every((k) => k == 0);

  Poly operator +(Poly o) {
    final r = <int, Lin>{};
    for (final k in {...c.keys, ...o.c.keys}) {
      r[k] = coef(k) + o.coef(k);
    }
    return Poly(r);
  }

  Poly operator -(Poly o) => this + (-o);
  Poly operator -() => Poly({for (final e in c.entries) e.key: -e.value});

  Poly operator *(Poly o) {
    final r = <int, Lin>{};
    for (final a in c.entries) {
      for (final b in o.c.entries) {
        final k = a.key + b.key;
        r[k] = (r[k] ?? Lin.zero) + a.value * b.value;
      }
    }
    return Poly(r);
  }

  Poly powInt(int n) {
    var r = Poly.constant(Rational.one);
    for (var i = 0; i < n; i++) {
      r = r * this;
    }
    return r;
  }
}

enum _T { num, x, a, plus, minus, star, slash, caret, lp, rp, end }

class _Tok {
  final _T t;
  final String s;
  final Rational? v;
  const _Tok(this.t, this.s, [this.v]);
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

List<_Tok> _lex(String s) {
  final out = <_Tok>[];
  var i = 0;
  while (i < s.length) {
    final ch = s[i];
    if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
      i++;
      continue;
    }
    if (_isDigit(ch) || ch == '.') {
      var j = i;
      var ip = '';
      var fp = '';
      var dot = false;
      while (j < s.length && (_isDigit(s[j]) || (s[j] == '.' && !dot))) {
        if (s[j] == '.') {
          dot = true;
        } else if (dot) {
          fp += s[j];
        } else {
          ip += s[j];
        }
        j++;
      }
      if (ip.isEmpty && fp.isEmpty) throw ParseError('Invalid number.');
      final digits = (ip.isEmpty ? '0' : ip) + fp;
      out.add(_Tok(
        _T.num,
        s.substring(i, j),
        Rational(BigInt.parse(digits), BigInt.from(10).pow(fp.length)),
      ));
      i = j;
      continue;
    }
    switch (ch) {
      case '+':
        out.add(_Tok(_T.plus, ch));
        break;
      case '-':
        out.add(_Tok(_T.minus, ch));
        break;
      case '*':
        out.add(_Tok(_T.star, ch));
        break;
      case '/':
        out.add(_Tok(_T.slash, ch));
        break;
      case '^':
        out.add(_Tok(_T.caret, ch));
        break;
      case '(':
        out.add(_Tok(_T.lp, ch));
        break;
      case ')':
        out.add(_Tok(_T.rp, ch));
        break;
      case 'x':
        out.add(_Tok(_T.x, ch));
        break;
      case 'a':
        out.add(_Tok(_T.a, ch));
        break;
      default:
        throw ParseError("Unknown symbol '$ch'. Use x, a, numbers and + - * / ^ ( )");
    }
    i++;
  }
  out.add(const _Tok(_T.end, ''));
  return out;
}

class _Parser {
  final List<_Tok> toks;
  int p = 0;
  _Parser(this.toks);

  _Tok get cur => toks[p];

  Poly parseAll() {
    final r = _expr();
    if (cur.t != _T.end) throw ParseError("Unexpected '${cur.s}'.");
    return r;
  }

  Poly _expr() {
    var r = _term();
    while (cur.t == _T.plus || cur.t == _T.minus) {
      final plus = cur.t == _T.plus;
      p++;
      final t = _term();
      r = plus ? r + t : r - t;
    }
    return r;
  }

  bool get _startsAtom =>
      cur.t == _T.x || cur.t == _T.a || cur.t == _T.lp;

  Poly _term() {
    var r = _unary();
    while (true) {
      if (cur.t == _T.star) {
        p++;
        r = r * _unary();
      } else if (cur.t == _T.slash) {
        p++;
        r = _divide(r, _unary());
      } else if (_startsAtom) {
        r = r * _power(); // implicit multiplication: 3x, 2(x+1), (x+1)(x-1)
      } else {
        break;
      }
    }
    return r;
  }

  Poly _unary() {
    if (cur.t == _T.minus) {
      p++;
      return -_unary();
    }
    if (cur.t == _T.plus) {
      p++;
      return _unary();
    }
    return _power();
  }

  Poly _power() {
    final base = _atom();
    if (cur.t == _T.caret) {
      p++;
      final e = _unary();
      return base.powInt(_asExponent(e));
    }
    return base;
  }

  int _asExponent(Poly e) {
    final v = e.coef(0);
    if (!e.isConstant ||
        v.hasParam ||
        !v.k.isInteger ||
        v.k.isNegative ||
        v.k > Rational.fromInt(8)) {
      throw ParseError('Exponent must be a whole number from 0 to 8.');
    }
    return v.k.numer.toInt();
  }

  Poly _atom() {
    final t = cur;
    switch (t.t) {
      case _T.num:
        p++;
        return Poly.constant(t.v!);
      case _T.x:
        p++;
        return Poly.x();
      case _T.a:
        p++;
        return Poly.param();
      case _T.lp:
        p++;
        final r = _expr();
        if (cur.t != _T.rp) throw ParseError("Missing ')'.");
        p++;
        return r;
      default:
        throw ParseError(t.t == _T.end
            ? 'The expression ended unexpectedly.'
            : "Unexpected '${t.s}'.");
    }
  }

  Poly _divide(Poly n, Poly d) {
    if (!d.isConstant || d.hasParam) {
      throw ParseError('Division is only supported by plain numbers.');
    }
    final v = d.coef(0).k;
    if (v.isZero) throw ParseError('Division by zero.');
    return n * Poly.constant(Rational.one / v);
  }
}

Poly parsePolynomial(String raw) {
  var s = normalizeMath(raw).toLowerCase().replaceAll('**', '^');
  s = s
      .replaceAll('[', '(')
      .replaceAll(']', ')')
      .replaceAll('{', '(')
      .replaceAll('}', ')');
  if (s.trim().isEmpty) throw ParseError('Nothing to read.');
  return _Parser(_lex(s)).parseAll();
}

/// Parses an exact constant such as -2, 0.25, 3/4, (1+2)/3.
Rational parseConstant(String raw, {String what = 'Value'}) {
  if (raw.trim().isEmpty) throw ParseError('$what: enter a number.');
  final p = parsePolynomial(raw);
  if (!p.isConstant || p.hasParam) {
    throw ParseError('$what must be a plain number.');
  }
  return p.coef(0).k;
}
