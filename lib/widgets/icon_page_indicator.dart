import 'package:flutter/material.dart';
import 'package:neumorphic_calculator/widgets/glass.dart';

class IconPageIndicator extends StatefulWidget {
  final PageController controller;
  final List<IconData> icons;
  final Duration duration;
  final double? buttonRadius;

  const IconPageIndicator({
    super.key,
    required this.controller,
    required this.icons,
    this.duration = const Duration(milliseconds: 300),
    this.buttonRadius,
  });

  @override
  State<IconPageIndicator> createState() => _IconPageIndicatorState();
}

class _IconPageIndicatorState extends State<IconPageIndicator> {
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = widget.controller.page?.round() ?? 0;
    if (page != currentPage && mounted) {
      setState(() => currentPage = page);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = GlassPalette.of(context);
    final primary = palette.accent;

    return SizedBox(
      height: kToolbarHeight,
      child: Center(
        child: GlassSurface(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.icons.length, (index) {
              final isSelected = index == currentPage;

              return GestureDetector(
                onTap: () => widget.controller.animateToPage(index,
                    duration: widget.duration, curve: Curves.easeOut),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: isSelected ? 1.0 : 0.85,
                    end: isSelected ? 1.0 : 0.85,
                  ),
                  duration: widget.duration,
                  curve: Curves.easeOut,
                  builder: (context, scale, child) {
                    return AnimatedContainer(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isSelected
                            ? primary.withValues(alpha: 0.32)
                            : Colors.transparent,
                      ),
                      duration: Duration(milliseconds: 200),
                      child: Transform.scale(
                        scale: scale,
                        child: Icon(
                          widget.icons[index],
                          size: 20,
                          color: isSelected
                              ? palette.onGlass
                              : palette.onGlassMuted,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
