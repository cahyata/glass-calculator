import 'package:flutter/material.dart';
import 'package:neumorphic_calculator/widgets/glass.dart';
import 'package:neumorphic_calculator/widgets/neumorphic_button.dart';

/// A key in the scientific tray: what it shows and what it types.
class SciKey {
  const SciKey(this.label, this.token, {this.semantic});
  final String label;
  final String token;
  final String? semantic;
}

/// Token the panel emits for the "Ans" key; the controller swaps it for the
/// last result.
const String kAnsToken = 'Ans';

List<List<SciKey>> scientificKeys({required bool inverse}) => [
      [
        inverse
            ? const SciKey('sin⁻¹', 'sin⁻¹(', semantic: 'Inverse sine')
            : const SciKey('sin', 'sin(', semantic: 'Sine'),
        inverse
            ? const SciKey('cos⁻¹', 'cos⁻¹(', semantic: 'Inverse cosine')
            : const SciKey('cos', 'cos(', semantic: 'Cosine'),
        inverse
            ? const SciKey('tan⁻¹', 'tan⁻¹(', semantic: 'Inverse tangent')
            : const SciKey('tan', 'tan(', semantic: 'Tangent'),
        inverse
            ? const SciKey('eˣ', 'e^(', semantic: 'e to the power')
            : const SciKey('ln', 'ln(', semantic: 'Natural logarithm'),
        inverse
            ? const SciKey('10ˣ', '10^(', semantic: 'Ten to the power')
            : const SciKey('log', 'log(', semantic: 'Logarithm base ten'),
      ],
      [
        inverse
            ? const SciKey('x³', '^3', semantic: 'Cube')
            : const SciKey('x²', '^2', semantic: 'Square'),
        const SciKey('xʸ', '^', semantic: 'Power'),
        inverse
            ? const SciKey('∛', '∛(', semantic: 'Cube root')
            : const SciKey('√', '√(', semantic: 'Square root'),
        const SciKey('x!', '!', semantic: 'Factorial'),
        const SciKey('1/x', '^-1', semantic: 'Reciprocal'),
      ],
      [
        const SciKey('π', 'π', semantic: 'Pi'),
        const SciKey('e', 'e', semantic: "Euler's number"),
        const SciKey('|x|', 'abs(', semantic: 'Absolute value'),
        const SciKey('EE', 'E', semantic: 'Times ten to the power'),
        const SciKey('Ans', kAnsToken, semantic: 'Last answer'),
      ],
    ];

class ScientificPanel extends StatelessWidget {
  const ScientificPanel({
    super.key,
    required this.expanded,
    required this.inverse,
    required this.degrees,
    required this.onToggleExpanded,
    required this.onToggleInverse,
    required this.onToggleAngle,
    required this.onKey,
  });

  final bool expanded;
  final bool inverse;
  final bool degrees;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleInverse;
  final VoidCallback onToggleAngle;
  final void Function(String token) onKey;

  static const double _keyHeight = 38;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final palette = GlassPalette.of(context);
    final labelStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: palette.onGlass,
    );

    Widget pill(String label, VoidCallback onTap,
            {bool active = false, String? semantic}) =>
        NeumorphicButton(
          constraints:
              const BoxConstraints(minWidth: 58, minHeight: 32, maxHeight: 32),
          borderRadius: 16,
          tone: active ? GlassTone.tinted : GlassTone.neutral,
          semanticLabel: semantic ?? label,
          onPressed: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4)),
          ),
        );

    final keys = scientificKeys(inverse: inverse);

    return GlassSurface(
      radius: 26,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              pill(degrees ? 'DEG' : 'RAD', onToggleAngle,
                  semantic: degrees
                      ? 'Angle mode degrees, switch to radians'
                      : 'Angle mode radians, switch to degrees'),
              const SizedBox(width: _gap),
              pill('2nd', onToggleInverse,
                  active: inverse, semantic: 'Second functions'),
              const Spacer(),
              Text('Scientific',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: palette.onGlassMuted)),
              const SizedBox(width: _gap),
              NeumorphicButton(
                constraints:
                    const BoxConstraints.tightFor(width: 40, height: 32),
                borderRadius: 16,
                semanticLabel:
                    expanded ? 'Hide scientific keys' : 'Show scientific keys',
                onPressed: onToggleExpanded,
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.keyboard_arrow_down, size: 20),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: _gap),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var r = 0; r < keys.length; r++) ...[
                          if (r > 0) const SizedBox(height: _gap),
                          Row(
                            children: [
                              for (var c = 0; c < keys[r].length; c++) ...[
                                if (c > 0) const SizedBox(width: _gap),
                                Expanded(
                                  child: NeumorphicButton(
                                    constraints: const BoxConstraints.tightFor(
                                        height: _keyHeight),
                                    borderRadius: _keyHeight / 2,
                                    semanticLabel: keys[r][c].semantic,
                                    onPressed: () => onKey(keys[r][c].token),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(keys[r][c].label,
                                          style: labelStyle),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
