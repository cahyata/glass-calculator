import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:neumorphic_calculator/screens/calculator_screen/calculator_controller.dart';
import 'package:neumorphic_calculator/screens/dashboard_screen/dashboard_controller.dart';
import 'package:neumorphic_calculator/screens/calculator_screen/calculator_screen.dart';
import 'package:neumorphic_calculator/screens/history_screen/history_screen.dart';
import 'package:neumorphic_calculator/screens/settings_screen/settings_screen.dart';
import 'package:neumorphic_calculator/tutorial_screen.dart';
import 'package:neumorphic_calculator/utils/extensions/extensions.dart';
import 'package:neumorphic_calculator/widgets/calculator_app_bar.dart';
import 'package:neumorphic_calculator/widgets/circular_wipe_overlay_widget.dart';
import 'package:neumorphic_calculator/widgets/custom_scroll_physics.dart';
import 'package:neumorphic_calculator/widgets/glass.dart';
import 'package:neumorphic_calculator/widgets/input_widget.dart';
import 'package:neumorphic_calculator/widgets/keep_alive_wrapper.dart';
import 'package:neumorphic_calculator/widgets/result_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Keeps the phone layout on wide windows (web, desktop, tablets).
  static const double _maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = GlassPalette.of(context);
    return GetBuilder<DashboardController>(builder: (dashCtrl) {
      return PopScope(
        canPop: dashCtrl.index == 1,
        onPopInvokedWithResult: (val, _) {
          if (val) return;
          dashCtrl.animateToPage(1);
        },
        child: TutorialScreen(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: theme.appBarTheme.systemOverlayStyle?.copyWith(
                  systemNavigationBarColor: theme.scaffoldBackgroundColor,
                ) ??
                SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: LiquidBackground(
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _maxWidth),
                      child: Column(
                        children: [
                          const CalculatorAppBar(),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                              child: GlassSurface(
                                radius: 34,
                                child: GetBuilder<CalculatorController>(
                                  builder: (controller) {
                                    return CircularWipeOverlayWidget(
                                      triggerWipe: controller.isClearing,
                                      onWipeComplete: controller.onWipeComplete,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        20, 14, 20, 0),
                                                child: Text(
                                                  controller.isDegree
                                                      ? 'DEG'
                                                      : 'RAD',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1.2,
                                                    color: palette.onGlassMuted,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Center(
                                                child: InputWidget(
                                                    controller.textCtrl),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: ResultWidget(
                                                controller.output
                                                    .formatExpression(),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 11,
                            child: PageView(
                              physics: CustomScrollPhysics(),
                              onPageChanged: (index) {
                                dashCtrl.index = index;
                                dashCtrl.update();
                              },
                              controller: dashCtrl.pageController,
                              children: const [
                                KeepAliveWrapper(child: SettingsScreen()),
                                KeepAliveWrapper(child: CalculatorScreen()),
                                KeepAliveWrapper(child: HistoryScreen())
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
