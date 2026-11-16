import 'package:flutter/material.dart';
import '../core/analyzer.dart';
import '../core/models.dart';

class AppController extends ChangeNotifier {
  final function = TextEditingController(text: 'f(x) = 4x^2 - 3x');
  final left = TextEditingController(text: '-2');
  final right = TextEditingController(text: '3');
  final setText = TextEditingController(text: '-2, 0, 1, 2, 4');
  final query = TextEditingController(text: '-2, 1, 5');
  final condition = TextEditingController();

  DomainMode mode = DomainMode.interval;
  bool leftClosed = true;
  bool rightClosed = false;
  bool leftInf = false;
  bool rightInf = false;

  int page = 0; // 0 Input, 1 Steps, 2 Number line, 3 Graph
  AnalysisResult? result;
  String? error;
  bool needsCondition = false;
  final statusKey = GlobalKey();

  String _sig = '';
  bool _batch = false;

  static const pageLabels = ['Solve', 'Number line', 'Graph', 'Input'];
  String get nextLabel => pageLabels[page];

  AppController() {
    for (final c in [function, left, right, setText, query, condition]) {
      c.addListener(_onText);
    }
    _recompute();
  }

  List<TextEditingController> get _all =>
      [function, left, right, setText, query, condition];

  void _onText() {
    if (_batch) return;
    final sig = _all.map((c) => c.text).join('\u0001');
    if (sig == _sig) return; // cursor moves must not rebuild everything
    _recompute();
    notifyListeners();
  }

  InputData get _input => InputData(
        function: function.text,
        condition: condition.text,
        mode: mode,
        leftText: left.text,
        rightText: right.text,
        leftClosed: leftClosed,
        rightClosed: rightClosed,
        leftInf: leftInf,
        rightInf: rightInf,
        setText: setText.text,
        queryText: query.text,
      );

  void _recompute() {
    _sig = _all.map((c) => c.text).join('\u0001');
    needsCondition = functionUsesParam(function.text);
    try {
      result = analyze(_input);
      error = null;
    } on ParseError catch (e) {
      result = null;
      error = e.message;
    } catch (_) {
      result = null;
      error = 'Could not read the input.';
    }
  }

  void _changed() {
    _recompute();
    notifyListeners();
  }

  void setMode(DomainMode m) {
    mode = m;
    _changed();
  }

  void toggleLeftClosed() {
    if (leftInf) return;
    leftClosed = !leftClosed;
    _changed();
  }

  void toggleRightClosed() {
    if (rightInf) return;
    rightClosed = !rightClosed;
    _changed();
  }

  void toggleLeftInf() {
    leftInf = !leftInf;
    if (leftInf) leftClosed = false;
    _changed();
  }

  void toggleRightInf() {
    rightInf = !rightInf;
    if (rightInf) rightClosed = false;
    _changed();
  }

  void loadPreset(int i) {
    _batch = true;
    condition.text = '';
    switch (i) {
      case 0: // Quadratic on a half-open interval
        function.text = 'f(x) = 4x^2 - 3x';
        mode = DomainMode.interval;
        left.text = '-2';
        right.text = '3';
        leftClosed = true;
        rightClosed = false;
        leftInf = false;
        rightInf = false;
        query.text = '-2, 1, 5';
        break;
      case 1: // Solve a
        function.text = 'h(x) = 3x + a';
        condition.text = 'h(1) = 2';
        mode = DomainMode.discrete;
        setText.text = '-2, 0, 1, 2, 4';
        query.text = '1, 0, 5';
        break;
      case 2: // Discrete set
        function.text = 'f(x) = 4x^2 - 3x';
        mode = DomainMode.discrete;
        setText.text = '-2, 0, 1, 2, 4';
        query.text = '-2, 1, 5';
        break;
      default: // Half-open
        function.text = 'g(x) = x^2 - 4x + 1';
        mode = DomainMode.interval;
        left.text = '-1';
        right.text = '5';
        leftClosed = false;
        rightClosed = true;
        leftInf = false;
        rightInf = false;
        query.text = '-1, 0, 5';
    }
    _batch = false;
    _changed();
  }

  /// The one big bottom button: Input → Steps → Number line → Graph → Input.
  void next() {
    if (page == 0) {
      _recompute();
      if (result == null) {
        notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = statusKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(ctx,
                duration: const Duration(milliseconds: 250), alignment: 0.5);
          }
        });
        return;
      }
      page = 1;
    } else {
      page = (page + 1) % 4;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }
}
