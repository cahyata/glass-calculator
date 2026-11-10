import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension ColorExtension on Color {
  ThemeData getTheme(TextTheme textTheme, {Brightness? brightness}) {
    return ThemeData(
        textTheme: textTheme,
        splashColor: const Color.fromRGBO(207, 88, 41, 1),
        scaffoldBackgroundColor: brightness == Brightness.dark
            ? const Color(0xFF0B0E22)
            : const Color(0xFFEAF0FF),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: brightness == Brightness.dark
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: const Color(0xFF0B0E22),
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: const Color(0xFFEAF0FF),
                ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: this,
          brightness: brightness ?? Brightness.light,
        ));
  }
}
