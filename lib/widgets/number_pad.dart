import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:neumorphic_calculator/calculator_icons.dart';
import 'package:neumorphic_calculator/utils/enum.dart';
import 'package:neumorphic_calculator/widgets/glass.dart';
import 'package:neumorphic_calculator/widgets/neumorphic_button.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    this.onNumberPressed,
    this.onOperationPressed,
    required this.borderRadius,
  });

  final void Function(String number)? onNumberPressed;
  final void Function(CalculatorButton button)? onOperationPressed;
  final double borderRadius;

  static const double _gap = 12;
  static const int _rows = 5;
  static const int _cols = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final cell = math
          .min(
            (box.maxWidth - _gap * (_cols + 1)) / _cols,
            (box.maxHeight - _gap * (_rows + 1)) / _rows,
          )
          .clamp(20.0, 88.0);
      final numberStyle =
          TextStyle(fontSize: cell * 0.42, fontWeight: FontWeight.w500);
      final actionStyle =
          TextStyle(fontSize: cell * 0.36, fontWeight: FontWeight.w600);
      final iconSize = cell * 0.36;
      final size = BoxConstraints.tightFor(width: cell, height: cell);

      void op(CalculatorButton b) => onOperationPressed?.call(b);

      Widget digit(String d) => NeumorphicButton(
            constraints: size,
            borderRadius: borderRadius,
            semanticLabel: d,
            onPressed: () => onNumberPressed?.call(d),
            child: Text(d, style: numberStyle),
          );

      Widget action(CalculatorButton b, Widget child,
              {GlassTone tone = GlassTone.bright, String? label}) =>
          NeumorphicButton(
            constraints: size,
            borderRadius: borderRadius,
            tone: tone,
            semanticLabel: label ?? b.value,
            onPressed: () => op(b),
            child: child,
          );

      Widget operator(CalculatorButton b, IconData icon, String label) =>
          action(b, Icon(icon, size: iconSize),
              tone: GlassTone.tinted, label: label);

      final rows = <List<Widget>>[
        [
          action(CalculatorButton.allClear, Text('AC', style: actionStyle),
              label: 'All clear'),
          _SplitButton(
            size: cell,
            borderRadius: borderRadius,
            style: actionStyle,
            onLeft: () => op(CalculatorButton.openParenthesis),
            onRight: () => op(CalculatorButton.closeParenthesis),
          ),
          action(CalculatorButton.percent,
              Icon(CalculatorIcons.percentage, size: iconSize),
              label: 'Percent'),
          operator(CalculatorButton.divide, CalculatorIcons.divide, 'Divide'),
        ],
        [
          digit('7'),
          digit('8'),
          digit('9'),
          operator(
              CalculatorButton.multiply, CalculatorIcons.cancel, 'Multiply'),
        ],
        [
          digit('4'),
          digit('5'),
          digit('6'),
          operator(
              CalculatorButton.subtract, CalculatorIcons.minus, 'Subtract'),
        ],
        [
          digit('1'),
          digit('2'),
          digit('3'),
          operator(CalculatorButton.add, CalculatorIcons.plus, 'Add'),
        ],
        [
          digit('0'),
          action(CalculatorButton.decimal, Text('.', style: numberStyle),
              tone: GlassTone.neutral, label: 'Decimal point'),
          action(CalculatorButton.clear,
              Icon(Icons.backspace_outlined, size: iconSize),
              tone: GlassTone.neutral, label: 'Backspace'),
          action(
              CalculatorButton.equal,
              Text('=',
                  style: TextStyle(
                      fontSize: cell * 0.46, fontWeight: FontWeight.w500)),
              tone: GlassTone.filled,
              label: 'Equals'),
        ],
      ];

      return RepaintBoundary(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0) const SizedBox(height: _gap),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var c = 0; c < rows[r].length; c++) ...[
                      if (c > 0) const SizedBox(width: _gap),
                      rows[r][c],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

/// One glass key split into "(" and ")" halves.
class _SplitButton extends StatelessWidget {
  const _SplitButton({
    required this.size,
    required this.borderRadius,
    required this.style,
    required this.onLeft,
    required this.onRight,
  });

  final double size;
  final double borderRadius;
  final TextStyle style;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    final palette = GlassPalette.of(context);
    final half = (size - 3) / 2;
    final outer = Radius.circular(math.min(borderRadius, size / 2));
    const inner = Radius.circular(6);

    Widget side(String label, VoidCallback onTap, BorderRadius radius) =>
        _HalfKey(
          width: half,
          height: size,
          radius: radius,
          palette: palette,
          onTap: onTap,
          child: Text(label, style: style.copyWith(color: palette.onGlass)),
        );

    return SizedBox(
      width: size,
      height: size,
      child: Row(
        children: [
          side('(', onLeft, BorderRadius.horizontal(left: outer, right: inner)),
          const SizedBox(width: 3),
          side(
              ')', onRight, BorderRadius.horizontal(left: inner, right: outer)),
        ],
      ),
    );
  }
}

class _HalfKey extends StatefulWidget {
  const _HalfKey({
    required this.width,
    required this.height,
    required this.radius,
    required this.palette,
    required this.onTap,
    required this.child,
  });

  final double width, height;
  final BorderRadius radius;
  final GlassPalette palette;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_HalfKey> createState() => _HalfKeyState();
}

class _HalfKeyState extends State<_HalfKey> {
  bool _pressed = false;

  void _set(bool v) {
    if (mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final lift = _pressed ? 0.16 : 0.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) {
        widget.onTap();
        Future.delayed(const Duration(milliseconds: 120), () => _set(false));
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: widget.radius,
            border: Border.all(
                color: Colors.white.withValues(alpha: p.isDark ? 0.28 : 0.8),
                width: 1),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: p.isDark
                  ? [
                      Colors.white.withValues(alpha: 0.34 + lift),
                      Colors.white.withValues(alpha: 0.14 + lift),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.55 + lift),
                    ],
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
