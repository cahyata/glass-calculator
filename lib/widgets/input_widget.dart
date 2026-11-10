import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:neumorphic_calculator/widgets/glass.dart';

class InputWidget extends StatelessWidget {
  final TextEditingController controller;

  const InputWidget(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = GlassPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: AutoSizeTextField(
        controller: controller,
        autofocus: true,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w300,
          color: palette.onGlass,
        ),
        minFontSize: 14,
        maxFontSize: 56,
        maxLines: 1,
        cursorColor: palette.accent,
        cursorWidth: 3,
        cursorRadius: const Radius.circular(2),
        showCursor: true,
        readOnly: true,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }
}
