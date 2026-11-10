import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:neumorphic_calculator/screens/history_screen/history_controller.dart';
import 'package:neumorphic_calculator/screens/settings_screen/settings_controller.dart';
import 'package:neumorphic_calculator/utils/extensions/extensions.dart';
import 'package:neumorphic_calculator/utils/math_engine.dart';
import 'package:neumorphic_calculator/utils/result_model.dart';
import 'package:neumorphic_calculator/widgets/scientific_panel.dart';

class CalculatorController extends GetxController {
  static CalculatorController get instance => Get.find<CalculatorController>();

  String output = '';

  String get exp => textCtrl.text;

  bool isClearing = false;

  /// Angle unit for trigonometric functions.
  bool isDegree = true;

  /// Whether the scientific keys show their second functions.
  bool isInverse = false;

  /// Whether the scientific tray is expanded.
  bool showScientific = true;

  /// Result of the last completed calculation, typed by the Ans key.
  String lastAnswer = '';
  final textCtrl = TextEditingController();

  int get baseOffset => textCtrl.selection.baseOffset;

  @override
  void dispose() {
    textCtrl.dispose();
    super.dispose();
  }

  void updateExpression(String newExp, int? newOffset,
      {bool autoCalculate = true}) {
    textCtrl.value = TextEditingValue(
      text: newExp.formatExpression(),
      selection: TextSelection.collapsed(offset: newOffset ?? -1),
    );
    if (autoCalculate) {
      if (newExp.canCalculate) {
        _calculate(skipError: true);
      } else {
        output = '';
      }
    }
    update();
  }

  void _addNumber(String number, [int? position]) {
    try {
      String newExp;
      int newOffset = -1;
      if (exp.isNoSelection(baseOffset)) {
        newExp = exp + number;
      } else {
        final rawExp = exp.removeCommas;
        final rawPosition = _mapFormattedOffsetToRaw(exp, position!);

        final result = rawExp.insertText(number, rawPosition);

        newExp = result.$1.formatExpression();
        newOffset = _mapRawOffsetToFormatted(result.$1, newExp, result.$2);
      }
      updateExpression(newExp, newOffset);
    } catch (_) {
      updateExpression(exp + number, null);
    }
  }

  void _addOperator(String operator, [int? position]) {
    String newExp;
    int newOffset = -1;
    if (exp.isNoSelection(position)) {
      if (exp.isEmpty) {
        // Only a leading minus makes sense on an empty expression.
        if (operator != '-') return;
        newExp = operator;
      } else if (operator == '-' &&
          exp.endsWithAny(['x', '÷', '+', '^', '('])) {
        newExp = (exp + operator);
      } else if (exp.endsWithOperator) {
        if (exp.length > 1) {
          newExp = (exp.substring(0, exp.length - 1) + operator);
        } else {
          newExp = operator;
        }
      } else {
        newExp = (exp + operator);
      }
    } else {
      final rawExp = exp.removeCommas;
      final rawPosition = _mapFormattedOffsetToRaw(exp, position!);

      final result = rawExp.insertText(operator, rawPosition);

      newExp = result.$1.formatExpression();
      newOffset = _mapRawOffsetToFormatted(result.$1, newExp, result.$2);
    }
    updateExpression(newExp, newOffset);
  }

  /// Inserts a scientific token (function, constant, power...) as-is.
  void _insertToken(String token, [int? position]) {
    if (exp.isNoSelection(position)) {
      updateExpression(exp + token, null);
      return;
    }
    final rawExp = exp.removeCommas;
    final rawPosition = _mapFormattedOffsetToRaw(exp, position!);
    final raw = rawExp.substring(0, rawPosition) +
        token +
        rawExp.substring(rawPosition);
    final formatted = raw.formatExpression();
    updateExpression(
      formatted,
      _mapRawOffsetToFormatted(raw, formatted, rawPosition + token.length),
    );
  }

  void _addDecimal([int? position]) {
    String newExp;
    int newOffset = -1;

    if (exp.isNoSelection(position)) {
      // The number currently being typed is the trailing run of digits.
      final current = RegExp(r'[\d.,]*$').stringMatch(exp) ?? '';
      if (current.contains('.')) return;
      newExp = current.isEmpty ? '${exp}0.' : '$exp.';
    } else {
      final rawExp = exp.removeCommas;
      final rawPosition = _mapFormattedOffsetToRaw(exp, position!);

      final result = rawExp.insertText('.', rawPosition, skipFormatting: true);

      newExp = result.$1.formatExpression();

      newOffset = _mapRawOffsetToFormatted(result.$1, newExp, result.$2);
    }
    updateExpression(newExp, newOffset);
  }

  void _calculate({bool skipError = false}) {
    if (!exp.isValidForCalculation) {
      output = '';
      return;
    }

    try {
      final result =
          exp.calculate(skipErrorChecking: skipError, degrees: isDegree);
      output = result.output;
    } catch (_) {
      output = 'Invalid expression';
    }
  }

  void _equals() {
    if (output.isEmpty ||
        output.contains('/') ||
        output.endsWithOperator ||
        output.toLowerCase().contains('error')) {
      return;
    }
    final newExp = output;
    lastAnswer = output;
    output = output.toDisplayFraction;
    updateExpression(newExp, null, autoCalculate: false);
  }

  void _delete([int? position]) {
    if (exp.isEmpty) return;

    if (exp.isNoSelection(position)) {
      // A function such as "sin(" is removed in one go.
      final fn = kFunctionTokens.firstWhereOrNull((f) => exp.endsWith(f));
      final newExp = fn != null
          ? exp.substring(0, exp.length - fn.length)
          : exp.removeLastChar;
      if (!newExp.canCalculate) {
        output = '';
      }
      updateExpression(newExp, null);
    } else {
      final result = exp.removeCharAt(position!);
      updateExpression(result.$1, result.$2);
    }
  }

  void _addParentheses(String p, [int? position]) {
    final isClose = p == ')';
    String newExp;
    int? newOffset;
    if (exp.isNoSelection(position)) {
      if (isClose) {
        final openCount = exp.count('(');
        final closeCount = exp.count(')');
        if (closeCount >= openCount) return; // prevent unbalanced close
      }
      newExp = (exp + p).formatExpression();
    } else {
      final result = exp.insertText(p, position!);
      newExp = result.$1;
      newOffset = result.$2;
    }
    updateExpression(newExp, newOffset);
  }

  /// Maps a cursor position in formatted text to raw text (without commas).
  int _mapFormattedOffsetToRaw(String formatted, int formattedOffset) {
    int rawOffset = 0;
    for (int i = 0; i < formattedOffset; i++) {
      if (formatted[i] != ',') {
        rawOffset++;
      }
    }
    return rawOffset;
  }

  /// Maps a cursor position in raw text to formatted text (with commas).
  int _mapRawOffsetToFormatted(String raw, String formatted, int rawOffset) {
    int count = 0;
    int formattedOffset = 0;
    while (formattedOffset < formatted.length && count < rawOffset) {
      if (formatted[formattedOffset] != ',') {
        count++;
      }
      formattedOffset++;
    }
    return formattedOffset;
  }

  void _mediumHaptic() {
    if (SettingsController.instance.state?.hapticEnabled ?? false) {
      HapticFeedback.mediumImpact();
    }
  }

  void _heavyHaptic() {
    if (SettingsController.instance.state?.hapticEnabled ?? false) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Records a completed calculation. Every evaluation is kept, repeats
  /// included; only failed ones and bare numbers (nothing was calculated)
  /// are skipped.
  void _saveResult(String expression, String output) {
    if (output.trim().isEmpty || output.toLowerCase().contains('error')) {
      return;
    }
    if (double.tryParse(expression.removeCommas) != null) return;
    Get.find<HistoryController>().addData(ResultModel(
      output: output,
      expression: expression,
      dateTime: DateTime.now(),
      degrees: isDegree,
    ));
  }

  /// Puts a past calculation back on the display, in its original angle mode.
  void loadFromHistory(ResultModel entry) {
    isDegree = entry.degrees;
    updateExpression(entry.expression, -1);
  }

  /// Uses a past result as a value: it continues the expression when an
  /// operator is waiting for an operand, otherwise it replaces it.
  void insertHistoryResult(String result) {
    final continues =
        exp.isNotEmpty && (exp.endsWithOperator || exp.endsWith('('));
    updateExpression(continues ? exp + result : result, -1);
  }

  void onClearAllPressed() {
    if (exp.isNotEmpty && output.isNotEmpty) {
      isClearing = true;
    } else {
      output = '';
      textCtrl.clear();
    }
    update();
    _heavyHaptic();
  }

  void onEqualPressed() {
    final exp = this.exp;
    _calculate();
    final result = output;
    _equals();
    _saveResult(exp, result);
    _heavyHaptic();
  }

  /// Handles a key from the scientific tray.
  void onTokenPressed(String token) {
    if (token == kAnsToken) {
      if (lastAnswer.isEmpty) return;
      token = lastAnswer;
    }
    _insertToken(token, baseOffset);
    if (isInverse) isInverse = false;
    update();
    _mediumHaptic();
  }

  void toggleAngleMode() {
    isDegree = !isDegree;
    if (exp.canCalculate) {
      _calculate(skipError: true);
    }
    update();
    _mediumHaptic();
  }

  void toggleInverse() {
    isInverse = !isInverse;
    update();
    _mediumHaptic();
  }

  void toggleScientific() {
    showScientific = !showScientific;
    update();
    _mediumHaptic();
  }

  void onDecimalPressed() {
    _addDecimal(baseOffset);
    _mediumHaptic();
  }

  void onOperatorPressed(String value) {
    _addOperator(value, baseOffset);
    _mediumHaptic();
  }

  void onDeletePressed() {
    _delete(baseOffset);
    _mediumHaptic();
  }

  void onParenthesesPressed(String value) {
    _addParentheses(value, baseOffset);
    _mediumHaptic();
  }

  void onNumberPressed(String number) {
    _addNumber(number, baseOffset);
    _mediumHaptic();
  }

  void onWipeComplete() {
    isClearing = false;
    output = '';
    textCtrl.clear();
    update();
  }
}
