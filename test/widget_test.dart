import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphic_calculator/utils/extensions/extensions.dart';
import 'package:neumorphic_calculator/utils/math_engine.dart';

void main() {
  double eval(String s, {bool degrees = true}) =>
      MathEngine.evaluate(s, degrees: degrees);

  group('MathEngine', () {
    test('basic arithmetic and precedence', () {
      expect(eval('2+3x4'), 14);
      expect(eval('(2+3)x4'), 20);
      expect(eval('10÷4'), 2.5);
      expect(eval('1,000+1'), 1001);
      expect(eval('-2^2'), -4);
      expect(eval('2^-1'), 0.5);
      expect(eval('2^3^2'), 512);
    });

    test('percent and factorial', () {
      expect(eval('50%'), 0.5);
      expect(eval('200x10%'), 20);
      expect(eval('5!'), 120);
      expect(eval('0!'), 1);
    });

    test('trigonometry respects the angle mode', () {
      expect(eval('sin(30)'), closeTo(0.5, 1e-12));
      expect(eval('cos(60)'), closeTo(0.5, 1e-12));
      expect(eval('tan(45)'), closeTo(1, 1e-12));
      expect(eval('sin(π÷2)', degrees: false), closeTo(1, 1e-12));
      expect(eval('sin⁻¹(0.5)'), closeTo(30, 1e-9));
      expect(eval('tan⁻¹(1)', degrees: false), closeTo(math.pi / 4, 1e-12));
    });

    test('logs, roots and constants', () {
      expect(eval('ln(e)'), closeTo(1, 1e-12));
      expect(eval('log(1000)'), closeTo(3, 1e-12));
      expect(eval('√(16)'), 4);
      expect(eval('∛(-27)'), closeTo(-3, 1e-12));
      expect(eval('abs(-7)'), 7);
      expect(eval('e^(2)'), closeTo(math.e * math.e, 1e-12));
    });

    test('implicit multiplication', () {
      expect(eval('2π'), closeTo(2 * math.pi, 1e-12));
      expect(eval('2(3+4)'), 14);
      expect(eval('3sin(30)'), closeTo(1.5, 1e-12));
      expect(eval('(2)(3)'), 6);
    });

    test('scientific notation', () {
      expect(eval('2E3'), 2000);
      expect(eval('1.5E-3+1'), closeTo(1.0015, 1e-12));
    });

    test('domain and syntax errors throw', () {
      expect(() => eval('1÷0'), throwsA(isA<MathError>()));
      expect(() => eval('√(-1)'), throwsA(isA<MathError>()));
      expect(() => eval('ln(0)'), throwsA(isA<MathError>()));
      expect(() => eval('tan(90)'), throwsA(isA<MathError>()));
      expect(() => eval('2+'), throwsA(isA<MathError>()));
      expect(() => eval('2.5!'), throwsA(isA<MathError>()));
    });

    test('format trims float noise', () {
      expect(MathEngine.format(0.1 + 0.2), '0.3');
      expect(MathEngine.format(14), '14');
      expect(MathEngine.format(math.sin(math.pi)), '0');
      expect(MathEngine.format(1.5e21), '1.5E21');
      expect(MathEngine.format(1.5e-7), '1.5E-7');
    });
  });

  group('expression helpers', () {
    test('calculate closes open parentheses', () {
      expect('sin(30'.calculate().output, '0.5');
      expect('2x(3+4'.calculate().output, '14');
    });

    test('calculate reports errors', () {
      expect('1÷0'.calculate().output, 'Math Error');
      expect('1÷0'.calculate(skipErrorChecking: true).output, '');
    });

    test('formatExpression keeps tokens and groups digits', () {
      expect('1000+sin(2000)'.formatExpression(), '1,000+sin(2,000)');
      expect('1.5E21'.formatExpression(), '1.5E21');
      expect('2π'.formatExpression(), '2π');
      expect('Math Error'.formatExpression(), 'Math Error');
    });

    test('canCalculate', () {
      expect('12'.canCalculate, isFalse);
      expect('12+'.canCalculate, isFalse);
      expect('sin('.canCalculate, isFalse);
      expect('π'.canCalculate, isTrue);
      expect('5!'.canCalculate, isTrue);
      expect('1,000+2'.canCalculate, isTrue);
    });
  });
}
