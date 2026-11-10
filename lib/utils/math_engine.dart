import 'dart:math' as math;

/// Thrown when an expression cannot be parsed or evaluated.
class MathError implements Exception {
  final String message;
  const MathError(this.message);
  @override
  String toString() => message;
}

/// Function tokens as they appear in the display. Each one ends with `(`.
const List<String> kFunctionTokens = [
  'sin⁻¹(',
  'cos⁻¹(',
  'tan⁻¹(',
  'sin(',
  'cos(',
  'tan(',
  'log(',
  'abs(',
  'ln(',
  '√(',
  '∛(',
];

/// Small recursive-descent evaluator for the calculator's display syntax.
///
/// Supports + - x ÷ ^, postfix ! and %, parentheses, implicit multiplication
/// (`2π`, `3(4)`, `2sin(30)`), the constants π and e, and the functions in
/// [kFunctionTokens].
class MathEngine {
  MathEngine(String source, {this.degrees = true})
      : _s = source.replaceAll(',', '').replaceAll(' ', '');

  final String _s;
  final bool degrees;
  int _i = 0;

  static double evaluate(String source, {bool degrees = true}) {
    final engine = MathEngine(source, degrees: degrees);
    final value = engine._expr();
    if (engine._i < engine._s.length) {
      throw const MathError('Format Error');
    }
    if (value.isNaN || value.isInfinite) throw const MathError('Math Error');
    return value;
  }

  /// Formats a value for the display: trims float noise, keeps integers
  /// integral and uses `E` for very large or very small magnitudes.
  static String format(double value) {
    if (value.abs() < 1e-12) return '0';
    final rounded = double.parse(value.toStringAsPrecision(12));
    if (rounded == rounded.roundToDouble() && rounded.abs() < 1e15) {
      return rounded.toInt().toString();
    }
    return rounded.toString().replaceAll('e+', 'E').replaceAll('e', 'E');
  }

  bool get _done => _i >= _s.length;
  String get _c => _s[_i];

  bool _eat(String token) {
    if (_s.startsWith(token, _i)) {
      _i += token.length;
      return true;
    }
    return false;
  }

  double _expr() {
    var value = _term();
    while (!_done) {
      if (_eat('+')) {
        value += _term();
      } else if (_eat('-')) {
        value -= _term();
      } else {
        break;
      }
    }
    return value;
  }

  double _term() {
    var value = _unary();
    while (!_done) {
      if (_eat('x') || _eat('*')) {
        value *= _unary();
      } else if (_eat('÷') || _eat('/')) {
        final divisor = _unary();
        if (divisor == 0) throw const MathError('Math Error');
        value /= divisor;
      } else if (_startsPrimary) {
        value *= _power();
      } else {
        break;
      }
    }
    return value;
  }

  bool get _startsPrimary {
    if (_done) return false;
    final c = _c;
    return c == '(' ||
        c == 'π' ||
        c == 'e' ||
        c == '.' ||
        _isDigit(c) ||
        kFunctionTokens.any((f) => _s.startsWith(f, _i));
  }

  double _unary() {
    if (_eat('-')) return -_unary();
    if (_eat('+')) return _unary();
    return _power();
  }

  double _power() {
    final base = _postfix();
    if (_eat('^')) {
      return math.pow(base, _unary()).toDouble();
    }
    return base;
  }

  double _postfix() {
    var value = _primary();
    while (!_done) {
      if (_eat('!')) {
        value = _factorial(value);
      } else if (_eat('%')) {
        value /= 100;
      } else {
        break;
      }
    }
    return value;
  }

  double _primary() {
    if (_done) throw const MathError('Format Error');

    if (_eat('(')) return _closeGroup();
    if (_eat('π')) return math.pi;
    if (_eat('e')) return math.e;

    for (final fn in kFunctionTokens) {
      if (_eat(fn)) return _apply(fn, _closeGroup());
    }

    return _number();
  }

  double _closeGroup() {
    final value = _expr();
    if (!_eat(')')) throw const MathError('Format Error');
    return value;
  }

  double _number() {
    final start = _i;
    while (!_done && (_isDigit(_c) || _c == '.')) {
      _i++;
    }
    if (_i == start) throw const MathError('Format Error');
    // Scientific notation, e.g. 1.5E-7
    if (!_done && _c == 'E') {
      var j = _i + 1;
      if (j < _s.length && (_s[j] == '+' || _s[j] == '-')) j++;
      final digitsStart = j;
      while (j < _s.length && _isDigit(_s[j])) {
        j++;
      }
      if (j == digitsStart) throw const MathError('Format Error');
      _i = j;
    }
    final parsed = double.tryParse(_s.substring(start, _i));
    if (parsed == null) throw const MathError('Format Error');
    return parsed;
  }

  double _apply(String fn, double x) {
    double toRad(double v) => degrees ? v * math.pi / 180 : v;
    double fromRad(double v) => degrees ? v * 180 / math.pi : v;

    switch (fn) {
      case 'sin(':
        return math.sin(toRad(x));
      case 'cos(':
        return math.cos(toRad(x));
      case 'tan(':
        final c = math.cos(toRad(x));
        if (c.abs() < 1e-15) throw const MathError('Math Error');
        return math.sin(toRad(x)) / c;
      case 'sin⁻¹(':
        if (x.abs() > 1) throw const MathError('Math Error');
        return fromRad(math.asin(x));
      case 'cos⁻¹(':
        if (x.abs() > 1) throw const MathError('Math Error');
        return fromRad(math.acos(x));
      case 'tan⁻¹(':
        return fromRad(math.atan(x));
      case 'ln(':
        if (x <= 0) throw const MathError('Math Error');
        return math.log(x);
      case 'log(':
        if (x <= 0) throw const MathError('Math Error');
        return math.log(x) / math.ln10;
      case '√(':
        if (x < 0) throw const MathError('Math Error');
        return math.sqrt(x);
      case '∛(':
        return x < 0
            ? -math.pow(-x, 1 / 3).toDouble()
            : math.pow(x, 1 / 3).toDouble();
      case 'abs(':
        return x.abs();
    }
    throw const MathError('Format Error');
  }

  double _factorial(double x) {
    if (x < 0 || x != x.roundToDouble() || x > 170) {
      throw const MathError('Math Error');
    }
    var result = 1.0;
    for (var k = 2; k <= x; k++) {
      result *= k;
    }
    return result;
  }

  static bool _isDigit(String c) {
    final u = c.codeUnitAt(0);
    return u >= 48 && u <= 57;
  }
}
