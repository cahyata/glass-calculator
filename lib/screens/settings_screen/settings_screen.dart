import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:neumorphic_calculator/controllers/theme_controller.dart';
import 'package:neumorphic_calculator/screens/settings_screen/settings_controller.dart';
import 'package:neumorphic_calculator/utils/enum.dart';
import 'package:neumorphic_calculator/utils/extensions/color_extension.dart';
import 'package:neumorphic_calculator/utils/extensions/extensions.dart';
import 'package:neumorphic_calculator/utils/settings_model.dart';
import 'package:neumorphic_calculator/widgets/button_radius_dialog.dart';
import 'package:neumorphic_calculator/widgets/glass.dart';
import 'package:system_theme/system_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeController get themeCtrl => ThemeController.instance;

  /// "sunsetOrange" -> "Sunset orange"
  static String _prettify(String camel) {
    final spaced =
        camel.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ');
    return spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
  }

  void _applyColor(SettingsModel settings, Color color,
      {ThemeColor? themeColor, required bool dynamicColor}) {
    final next = settings.copyWith(
      themeColor: themeColor ?? settings.themeColor,
      dynamicColor: dynamicColor,
    );
    SettingsController.instance.updateSettings(next);
    themeCtrl.updateTheme(
      color.getTheme(settings.font.textTheme),
      color.getTheme(settings.font.textTheme, brightness: Brightness.dark),
    );
  }

  void _pickFont(SettingsModel settings, bool isDark) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: isDark ? Colors.white : Colors.black,
        );
    showAdaptiveDialog<Fonts>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Font'),
          titleTextStyle: titleStyle,
          children: Fonts.values.map((font) {
            final theme = isDark
                ? font.setToTheme(themeCtrl.darkTheme)
                : font.setToTheme(themeCtrl.lightTheme);
            return Theme(
              data: theme,
              child: ListTile(
                trailing:
                    settings.font == font ? const Icon(Icons.check) : null,
                onTap: () {
                  if (font == settings.font) return Navigator.pop(context);
                  themeCtrl.updateTheme(font.setToTheme(themeCtrl.lightTheme),
                      font.setToTheme(themeCtrl.darkTheme));
                  SettingsController.instance
                      .updateSettings(settings.copyWith(font: font));
                  Navigator.pop(context);
                },
                title: Text(_prettify(font.name)),
                subtitle: const Text('This is demo text 1234567890'),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _pickRadius(SettingsModel settings) async {
    final result = await ButtonRadiusDialog(buttonRadius: settings.buttonRadius)
        .show(context);
    if (result is double) {
      SettingsController.instance
          .updateSettings(settings.copyWith(buttonRadius: result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = GlassPalette.of(context);
    final isDynamicColorAvailable =
        SystemTheme.accentColor.accent != SystemTheme.fallbackColor &&
            defaultTargetPlatform.supportsAccentColor;

    return GetBuilder<SettingsController>(builder: (settingsCtrl) {
      final settings = settingsCtrl.state ?? SettingsModel.normal();
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _SectionLabel('Appearance', palette),
            GlassSurface(
              radius: 26,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.onGlass)),
                  const SizedBox(height: 10),
                  GetBuilder<ThemeController>(builder: (_) {
                    return _ModeSelector(
                      value: themeCtrl.themeMode,
                      palette: palette,
                      onChanged: (mode) {
                        HapticFeedback.selectionClick();
                        themeCtrl.saveThemeMode(mode);
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  GetBuilder<ThemeController>(builder: (_) {
                    return Text(
                      switch (themeCtrl.themeMode) {
                        ThemeMode.system => 'Follows your device setting',
                        ThemeMode.light => 'Always light',
                        ThemeMode.dark => 'Always dark',
                      },
                      style:
                          TextStyle(fontSize: 12, color: palette.onGlassMuted),
                    );
                  }),
                  const SizedBox(height: 18),
                  Text('Accent color',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.onGlass)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      if (isDynamicColorAvailable)
                        _Swatch(
                          color: SystemTheme.accentColor.accent
                              .withValues(alpha: 1),
                          label: 'System accent',
                          selected: settings.dynamicColor,
                          palette: palette,
                          onTap: () => _applyColor(
                            settings,
                            SystemTheme.accentColor.accent.withValues(alpha: 1),
                            dynamicColor: true,
                          ),
                        ),
                      for (final themeColor in ThemeColor.values)
                        _Swatch(
                          color: themeColor.color,
                          label: _prettify(themeColor.name),
                          selected: !settings.dynamicColor &&
                              settings.themeColor == themeColor,
                          palette: palette,
                          onTap: () => _applyColor(
                            settings,
                            themeColor.color,
                            themeColor: themeColor,
                            dynamicColor: false,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _SectionLabel('Style', palette),
            GlassSurface(
              radius: 26,
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.text_fields_rounded,
                    title: 'Font',
                    value: _prettify(settings.font.name),
                    palette: palette,
                    onTap: () => _pickFont(settings, isDark),
                  ),
                  _Divider(palette),
                  _SettingRow(
                    icon: Icons.rounded_corner_rounded,
                    title: 'Button radius',
                    value: settings.buttonRadius.round().toString(),
                    palette: palette,
                    onTap: () => _pickRadius(settings),
                  ),
                ],
              ),
            ),
            _SectionLabel('Feedback', palette),
            GlassSurface(
              radius: 26,
              child: _SettingRow(
                icon: Icons.vibration_rounded,
                title: 'Haptic feedback',
                subtitle: 'Vibrate when you press a key',
                palette: palette,
                trailing: Switch(
                  value: settings.hapticEnabled,
                  onChanged: (value) =>
                      _setHaptic(settingsCtrl, settings, value),
                ),
                onTap: () =>
                    _setHaptic(settingsCtrl, settings, !settings.hapticEnabled),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _setHaptic(
      SettingsController ctrl, SettingsModel settings, bool enabled) {
    if (enabled) HapticFeedback.mediumImpact();
    ctrl.updateSettings(settings.copyWith(hapticEnabled: enabled));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.palette);

  final String text;
  final GlassPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: palette.onGlassMuted,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider(this.palette);

  final GlassPalette palette;

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 64,
        endIndent: 16,
        color: palette.onGlass.withValues(alpha: 0.10),
      );
}

/// One row of a settings card: tinted icon, title, optional value or
/// subtitle, and a trailing control (chevron by default).
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.palette,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final GlassPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: value == null ? title : '$title, $value',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.accent.withValues(alpha: 0.22),
                ),
                child: Icon(icon, size: 20, color: palette.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: palette.onGlass)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              fontSize: 12, color: palette.onGlassMuted)),
                  ],
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(value!,
                      style:
                          TextStyle(fontSize: 14, color: palette.onGlassMuted)),
                ),
              trailing ??
                  Icon(Icons.chevron_right_rounded,
                      color: palette.onGlassMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auto / Light / Dark as a labelled, sliding segmented control.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.value,
    required this.onChanged,
    required this.palette,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;
  final GlassPalette palette;

  static const _modes = <(ThemeMode, IconData, String)>[
    (ThemeMode.system, Icons.brightness_auto_rounded, 'Auto'),
    (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
    (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _modes.indexWhere((m) => m.$1 == value);
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: palette.isDark
            ? Colors.black.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.45),
        border: Border.all(
            color: palette.onGlass.withValues(alpha: 0.10), width: 1),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment(selected - 1.0, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / _modes.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      // Darker in light mode so the white label stays legible.
                      Color.lerp(palette.accent, Colors.black,
                          palette.isDark ? 0.05 : 0.30)!,
                      Color.lerp(palette.accent, Colors.black,
                          palette.isDark ? 0.25 : 0.48)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.4),
                      blurRadius: 14,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                for (final (mode, icon, label) in _modes)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: mode == value,
                      label: '$label theme',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(mode),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon,
                                size: 18,
                                color: mode == value
                                    ? Colors.white
                                    : palette.onGlassMuted),
                            const SizedBox(width: 6),
                            Text(label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: mode == value
                                      ? Colors.white
                                      : palette.onGlassMuted,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final GlassPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final checkColor =
        color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? palette.onGlass : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(color, Colors.white, 0.12)!, color],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: selected ? 0.55 : 0.25),
                    blurRadius: 10,
                    spreadRadius: -3,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: 20, color: checkColor)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
