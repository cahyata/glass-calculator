import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Colours shared by every glass surface, derived from the active theme.
class GlassPalette {
  GlassPalette._(this.isDark, this.primary);

  factory GlassPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPalette._(
        theme.brightness == Brightness.dark, theme.colorScheme.primary);
  }

  final bool isDark;
  final Color primary;

  static const Color darkBase = Color(0xFF0B0E22);
  static const Color lightBase = Color(0xFFEAF0FF);

  /// Main text colour on glass.
  Color get onGlass => isDark ? Colors.white : const Color(0xFF1B2038);

  /// Secondary text colour on glass.
  Color get onGlassMuted =>
      isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0x991B2038);

  /// Saturated accent that stays readable on both backgrounds.
  Color get accent {
    final hsl = HSLColor.fromColor(primary);
    return hsl
        .withSaturation(math.max(hsl.saturation, 0.7))
        .withLightness(isDark ? 0.55 : 0.48)
        .toColor();
  }

  List<Color> get backgroundGradient => isDark
      ? const [Color(0xFF070A1A), Color(0xFF10133A), Color(0xFF1C0F33)]
      : const [Color(0xFFE6EEFF), Color(0xFFF3ECFF), Color(0xFFFFF0F6)];
}

/// Slowly drifting colour orbs behind the whole app. Glass surfaces are
/// translucent, so this is what gives them something to refract.
class LiquidBackground extends StatefulWidget {
  const LiquidBackground({super.key, required this.child});

  final Widget child;

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = GlassPalette.of(context);
    final strength = palette.isDark ? 1.0 : 0.7;
    final orbs = <(Color, double, double, double)>[
      // colour, phase, size factor, alpha
      (palette.accent, 0.0, 1.15, 0.60 * strength),
      (const Color(0xFF3B82F6), 2.1, 1.0, 0.50 * strength),
      (const Color(0xFFEC4899), 4.2, 0.9, 0.38 * strength),
      (const Color(0xFF22D3EE), 5.5, 0.75, 0.32 * strength),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.backgroundGradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value * 2 * math.pi;
                return LayoutBuilder(builder: (context, box) {
                  final side = math.max(box.maxWidth, box.maxHeight * 0.6);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      for (final (color, phase, size, alpha) in orbs)
                        Align(
                          alignment: Alignment(
                            math.sin(t + phase) * 0.9,
                            math.cos(t * 2 + phase * 1.7) * 0.85,
                          ),
                          child: OverflowBox(
                            maxWidth: double.infinity,
                            maxHeight: double.infinity,
                            child: Container(
                              width: side * size,
                              height: side * size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  color.withValues(alpha: alpha),
                                  color.withValues(alpha: alpha * 0.35),
                                  color.withValues(alpha: 0),
                                ], stops: const [
                                  0.0,
                                  0.45,
                                  1.0
                                ]),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                });
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Paints the two things that make a flat translucent shape read as glass:
/// a soft gloss on the upper half and a bright-to-dim specular rim.
class GlassSheenPainter extends CustomPainter {
  const GlassSheenPainter({
    required this.radius,
    required this.isDark,
    this.intensity = 1.0,
  });

  final double radius;
  final bool isDark;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = math.min(radius, size.shortestSide / 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));
    final k = intensity * (isDark ? 1.0 : 1.25);

    final gloss = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: (0.20 * k).clamp(0, 1)),
          Colors.white.withValues(alpha: (0.04 * k).clamp(0, 1)),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.42, 0.6],
      ).createShader(rect);
    canvas.drawRRect(rrect, gloss);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: (0.75 * k).clamp(0, 1)),
          Colors.white.withValues(alpha: (0.12 * k).clamp(0, 1)),
          Colors.white.withValues(alpha: (0.05 * k).clamp(0, 1)),
          Colors.white.withValues(alpha: (0.40 * k).clamp(0, 1)),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(0.6), rim);
  }

  @override
  bool shouldRepaint(GlassSheenPainter old) =>
      old.radius != radius ||
      old.isDark != isDark ||
      old.intensity != intensity;
}

/// A frosted panel: blurs what is behind it, tints it and adds the sheen.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.blur = 24,
    this.tint,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Backdrop blur sigma. Pass 0 to skip the backdrop filter.
  final double blur;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final palette = GlassPalette.of(context);
    final fill = tint ??
        (palette.isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.42));

    Widget content = CustomPaint(
      foregroundPainter: GlassSheenPainter(
          radius: radius, isDark: palette.isDark, intensity: 0.7),
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (blur > 0) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.28 : 0.08),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}
