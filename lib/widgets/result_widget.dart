import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:neumorphic_calculator/widgets/glass.dart';

class ResultWidget extends StatelessWidget {
  final String result;

  const ResultWidget(this.result, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = GlassPalette.of(context);
    final isError = result.toLowerCase().contains('error');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      alignment: Alignment.centerRight,
      child: AutoSizeText(
        result,
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w500,
          color: isError
              ? const Color(0xFFFF6B6B)
              : Color.lerp(palette.accent, palette.onGlass, 0.25),
        ),
        minFontSize: 16,
        maxFontSize: 40,
        maxLines: 1,
      ),
    );
  }
}
