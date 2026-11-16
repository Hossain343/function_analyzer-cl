/// Exact rational number backed by BigInt.
/// Always stored in lowest terms with a positive denominator, so equality
/// and ordering are exact (no floating point error anywhere in the math core).
class Rational implements Comparable<Rational> {
  final BigInt numer;
  final BigInt denom;
  const Rational._(this.numer, this.denom);

  factory Rational(BigInt n, [BigInt? d]) {
    var nn = n;
    var dd = d ?? BigInt.one;
    if (dd == BigInt.zero) throw ArgumentError('Division by zero');
    if (dd.isNegative) {
      nn = -nn;
      dd = -dd;
    }
    final g = nn.gcd(dd);
    if (g > BigInt.one) {
      nn = nn ~/ g;
      dd = dd ~/ g;
    }
    return Rational._(nn, dd);
  }

  factory Rational.fromInt(int v) => Rational._(BigInt.from(v), BigInt.one);

  static final Rational zero = Rational.fromInt(0);
  static final Rational one = Rational.fromInt(1);
  static final Rational two = Rational.fromInt(2);

  bool get isZero => numer == BigInt.zero;
  bool get isNegative => numer.isNegative;
  bool get isPositive => numer > BigInt.zero;
  bool get isInteger => denom == BigInt.one;

  Rational operator +(Rational o) =>
      Rational(numer * o.denom + o.numer * denom, denom * o.denom);
  Rational operator -(Rational o) =>
      Rational(numer * o.denom - o.numer * denom, denom * o.denom);
  Rational operator *(Rational o) =>
      Rational(numer * o.numer, denom * o.denom);
  Rational operator /(Rational o) {
    if (o.isZero) throw ArgumentError('Division by zero');
    return Rational(numer * o.denom, denom * o.numer);
  }

  Rational operator -() => Rational._(-numer, denom);

  Rational abs() => isNegative ? -this : this;

  /// Non-negative integer power (exact).
  Rational pow(int e) {
    var r = Rational.one;
    for (var i = 0; i < e; i++) {
      r = r * this;
    }
    return r;
  }

  BigInt floor() {
    var q = numer ~/ denom;
    if (numer.isNegative && q * denom != numer) q -= BigInt.one;
    return q;
  }

  @override
  int compareTo(Rational other) =>
      (numer * other.denom).compareTo(other.numer * denom);

  bool operator <(Rational o) => compareTo(o) < 0;
  bool operator <=(Rational o) => compareTo(o) <= 0;
  bool operator >(Rational o) => compareTo(o) > 0;
  bool operator >=(Rational o) => compareTo(o) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Rational && numer == other.numer && denom == other.denom;

  @override
  int get hashCode => Object.hash(numer, denom);

  /// Only used for drawing. All displayed values stay exact.
  double toDouble() => numer.toDouble() / denom.toDouble();

  @override
  String toString() => isInteger ? numer.toString() : '$numer/$denom';
}
