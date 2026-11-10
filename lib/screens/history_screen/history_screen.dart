import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:neumorphic_calculator/screens/calculator_screen/calculator_controller.dart';
import 'package:neumorphic_calculator/screens/dashboard_screen/dashboard_controller.dart';
import 'package:neumorphic_calculator/screens/history_screen/history_controller.dart';
import 'package:neumorphic_calculator/screens/settings_screen/settings_controller.dart';
import 'package:neumorphic_calculator/utils/extensions/extensions.dart';
import 'package:neumorphic_calculator/utils/result_model.dart';
import 'package:neumorphic_calculator/utils/settings_model.dart';
import 'package:neumorphic_calculator/widgets/glass.dart';
import 'package:neumorphic_calculator/widgets/wipe_overlay_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 56, end: 0).animate(_controller);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat(date.year == now.year ? 'd MMMM' : 'd MMMM y')
        .format(date);
  }

  /// Flattens the history into day headers (String) and entries
  /// (index into the stored list).
  static List<Object> _rows(List<ResultModel> history) {
    final rows = <Object>[];
    String? lastLabel;
    for (var i = 0; i < history.length; i++) {
      final label = _dayLabel(history[i].dateTime);
      if (label != lastLabel) {
        rows.add(label);
        lastLabel = label;
      }
      rows.add(i);
    }
    return rows;
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Copied $text'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(builder: (settingsCtrl) {
      final settings = settingsCtrl.state ?? SettingsModel.normal();
      final showTip = settings.showHistoryTip;
      final theme = Theme.of(context);
      final palette = GlassPalette.of(context);
      final textStyle = theme.textTheme.bodyLarge?.copyWith(
        color: palette.onGlassMuted,
      );
      return GetBuilder<HistoryController>(builder: (ctrl) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final resultNotEmpty = ctrl.state?.isNotEmpty ?? false;
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: WipeOverlayList(
                triggerWipe: ctrl.isClearing.value,
                onWipeComplete: () {
                  ctrl.clearData();
                  ctrl.isClearing.value = false;
                },
                child: Column(
                  children: [
                    if (showTip && resultNotEmpty)
                      SizedBox(
                        height: _animation.value,
                        child: ClipRect(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: GlassSurface(
                              radius: 20,
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.info_outline,
                                    color: palette.accent),
                                title: Text(
                                  'Tap to reuse, swipe to delete',
                                  style: TextStyle(color: palette.onGlass),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.close,
                                      color: palette.onGlassMuted),
                                  onPressed: () {
                                    _controller.forward();
                                    settingsCtrl.updateSettings(settingsCtrl
                                            .state
                                            ?.copyWith(showHistoryTip: false) ??
                                        SettingsModel.normal());
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ctrl.obx(
                        (historyList) {
                          final rows = _rows(historyList!);
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final row = rows[i];
                              if (row is String) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 12, 8, 6),
                                  child: Text(
                                    row.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: palette.onGlassMuted,
                                    ),
                                  ),
                                );
                              }
                              final index = row as int;
                              return _HistoryTile(
                                key: ValueKey(
                                    '${historyList[index].dateTime.toIso8601String()}'
                                    '|${historyList[index].expression}'),
                                entry: historyList[index],
                                palette: palette,
                                onReuse: () {
                                  CalculatorController.instance
                                      .loadFromHistory(historyList[index]);
                                  DashboardController.instance.animateToPage(1);
                                },
                                onUseResult: () {
                                  CalculatorController.instance
                                      .insertHistoryResult(
                                          historyList[index].output);
                                  DashboardController.instance.animateToPage(1);
                                },
                                onCopy: () => _copy(historyList[index]
                                    .output
                                    .formatThousands()),
                                onDelete: () {
                                  HapticFeedback.mediumImpact();
                                  ctrl.removeAt(index);
                                },
                              );
                            },
                          );
                        },
                        onEmpty: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history,
                                  size: 40, color: palette.onGlassMuted),
                              const SizedBox(height: 8),
                              Text('No calculations yet', style: textStyle),
                              const SizedBox(height: 4),
                              Text('Press = to save one here',
                                  style: textStyle?.copyWith(fontSize: 13)),
                            ],
                          ),
                        ),
                        onLoading: const Center(
                          child: CircularProgressIndicator(),
                        ),
                        onError: (error) => Center(
                          child: Text(error ?? ' ', style: textStyle),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    });
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    super.key,
    required this.entry,
    required this.palette,
    required this.onReuse,
    required this.onUseResult,
    required this.onCopy,
    required this.onDelete,
  });

  final ResultModel entry;
  final GlassPalette palette;
  final VoidCallback onReuse;
  final VoidCallback onUseResult;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(fontSize: 13, color: palette.onGlassMuted);

    Widget action(IconData icon, String tooltip, VoidCallback onTap) =>
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: tooltip,
          icon: Icon(icon, size: 20, color: palette.onGlassMuted),
          onPressed: onTap,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Dismissible(
        key: ValueKey(
            'd|${entry.dateTime.toIso8601String()}|${entry.expression}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5A5F).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: GlassSurface(
          radius: 22,
          blur: 0,
          child: InkWell(
            onTap: onReuse,
            onLongPress: onCopy,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 6, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.expression,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15, color: palette.onGlassMuted)),
                        const SizedBox(height: 2),
                        Text('= ${entry.output.formatThousands()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: palette.onGlass)),
                        const SizedBox(height: 2),
                        Text(
                            '${entry.dateTime.timeAgo}'
                            '${entry.expression.containsAny([
                                  'sin',
                                  'cos',
                                  'tan'
                                ]) ? ' · ${entry.degrees ? 'DEG' : 'RAD'}' : ''}',
                            style: mutedStyle),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      action(Icons.call_made, 'Use result', onUseResult),
                      action(Icons.copy_rounded, 'Copy result', onCopy),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
