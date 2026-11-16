import 'package:flutter_test/flutter_test.dart';
import 'package:function_analyzer/core/analyzer.dart';
import 'package:function_analyzer/core/models.dart';

InputData discreteIn(String f, String values, String q, {String cond = ''}) => InputData(
    function: f, mode: DomainMode.discrete, setText: values, queryText: q, condition: cond);

InputData interval(String f, String l, bool lc, String r, bool rc, String q) =>
    InputData(
        function: f,
        mode: DomainMode.interval,
        leftText: l,
        rightText: r,
        leftClosed: lc,
        rightClosed: rc,
        queryText: q);

void main() {
  test('discrete set exam question', () {
    final r = analyze(discreteIn('f(x) = 4x^2 - 3x', '-2, 0, 1, 2, 4', '-2, 1, 5'));
    expect(r.funcText, 'f(x) = 4x² - 3x');
    expect(r.range.notation, '{0, 1, 10, 22, 52}');
    expect(r.queries[0].lines,
        ['4(-2)² - 3(-2)', '4·4 - 3(-2)', '16 - (-6)', '16 + 6', '22']);
    expect(r.queries[1].lines, ['4·1² - 3·1', '4·1 - 3·1', '4 - 3', '1']);
    expect(r.queries[2].inDomain, false);
  });

  test('half-open interval range is exact', () {
    final r = analyze(interval('f(x) = 4*x^2 - 3*x', '-2', true, '3', false, '1'));
    expect(r.range.notation, '[-9/16, 27)');
  });

  test('solve a', () {
    final r = analyze(discreteIn('h(x) = 3x + a', '-2, 0, 1, 2, 4', '1', cond: 'h(1) = 2'));
    expect(r.paramValue.toString(), '-1');
    expect(r.funcText, 'h(x) = 3x - 1');
  });

  test('range edge cases', () {
    expect(analyze(interval('x^2 - 4x + 1', '-1', false, '5', true, '')).range.notation, '[-3, 6]');
    expect(analyze(interval('x^2', '-1', false, '1', false, '')).range.notation, '[0, 1)');
    expect(analyze(interval('-x^2', '-1', false, '1', false, '')).range.notation, '(-1, 0]');
    expect(analyze(interval('2x - 1', '0', true, '3', false, '')).range.notation, '[-1, 5)');
    expect(analyze(interval('-2x', '0', true, '3', false, '')).range.notation, '(-6, 0]');
  });

  test('unicode and persian input', () {
    final r = analyze(discreteIn('f(x) = ۴x² − ۳x', '-۲، 0، 1', '1'));
    expect(r.funcText, 'f(x) = 4x² - 3x');
  });
}
