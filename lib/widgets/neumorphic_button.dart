import 'package:flutter/material.dart';
import 'package:neumorphic_calculator/widgets/glass.dart';

/// Visual weight of a glass button.
enum GlassTone {
  /// Barely-there glass, used for digits.
  neutral,

  /// Brighter glass, used for secondary actions (AC, %, parentheses).
  bright,

  /// Accent-tinted glass, used for operators and active toggles.
  tinted,

  /// Solid accent with a glow, used for the primary action.
  filled,
}

/// The app's button. It kept its original name so existing call sites still
/// work, but it now renders as a liquid-glass capsule.
class NeumorphicButton extends StatefulWidget {
  const NeumorphicButton({
    super.key,
    this.onPressed,
    this.onLongPress,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.duration,
    this.boxShadow,
    this.constraints,
    this.border,
    this.semanticLabel,
    this.tone = GlassTone.neutral,
  });

  final void Function()? onPressed;
  final void Function()? onLongPress;
  final double? width, height;
  final Duration? duration;
  final Widget child;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final BoxConstraints? constraints;
  final BoxBorder? border;
  final String? semanticLabel;
  final GlassTone tone;

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  void _handleTap() {
    widget.onPressed?.call();
    Future.delayed(const Duration(milliseconds: 120), () => _setPressed(false));
  }

  List<Color> _fill(GlassPalette p) {
    final lift = _pressed ? 0.16 : 0.0;
    switch (widget.tone) {
      case GlassTone.neutral:
        return p.isDark
            ? [
                Colors.white.withValues(alpha: 0.13 + lift),
                Colors.white.withValues(alpha: 0.04 + lift),
              ]
            : [
                Colors.white.withValues(alpha: 0.62 + lift),
                Colors.white.withValues(alpha: 0.30 + lift),
              ];
      case GlassTone.bright:
        return p.isDark
            ? [
                Colors.white.withValues(alpha: 0.30 + lift),
                Colors.white.withValues(alpha: 0.14 + lift),
              ]
            : [
                Colors.white.withValues(alpha: 0.90),
                Colors.white.withValues(alpha: 0.55 + lift),
              ];
      case GlassTone.tinted:
        return [
          p.accent.withValues(alpha: 0.72 + lift),
          p.accent.withValues(alpha: 0.44 + lift),
        ];
      case GlassTone.filled:
        return [
          Color.lerp(p.accent, Colors.white, 0.06 + lift)!,
          Color.lerp(p.accent, Colors.black, 0.22)!,
        ];
    }
  }

  List<BoxShadow> _shadows(GlassPalette p) {
    if (widget.boxShadow != null) return widget.boxShadow!;
    if (widget.tone == GlassTone.filled) {
      return [
        BoxShadow(
          color: p.accent.withValues(alpha: _pressed ? 0.7 : 0.45),
          blurRadius: _pressed ? 26 : 18,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: p.isDark ? 0.25 : 0.07),
        blurRadius: 14,
        spreadRadius: -7,
        offset: const Offset(0, 9),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = GlassPalette.of(context);
    final radius = widget.borderRadius ?? 18.0;
    final onAccent =
        widget.tone == GlassTone.tinted || widget.tone == GlassTone.filled;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _handleTap(),
        onTapCancel: () => _setPressed(false),
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: Duration(milliseconds: _pressed ? 90 : 260),
          curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
          child: ConstrainedBox(
            // Sizing lives outside the animated box so a resize is instant.
            constraints: widget.constraints ??
                const BoxConstraints(
                    minHeight: 55, maxHeight: 75, minWidth: 55, maxWidth: 75),
            child: CustomPaint(
              foregroundPainter: GlassSheenPainter(
                radius: radius,
                isDark: palette.isDark,
                intensity: _pressed ? 1.5 : 1.0,
              ),
              child: AnimatedContainer(
                alignment: Alignment.center,
                duration: widget.duration ?? const Duration(milliseconds: 160),
                height: widget.height,
                width: widget.width,
                decoration: BoxDecoration(
                  border: widget.border,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _fill(palette),
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: _shadows(palette),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                      color: onAccent ? Colors.white : palette.onGlass),
                  child: IconTheme.merge(
                    data: IconThemeData(
                        color: onAccent ? Colors.white : palette.onGlass),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
