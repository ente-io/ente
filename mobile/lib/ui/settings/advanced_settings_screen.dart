import 'package:flutter/material.dart';
import "package:photos/core/error-reporting/super_logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/user_remote_flag_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/settings/gallery_settings_screen.dart";
import "package:photos/ui/settings/ml/machine_learning_settings_page.dart";
import 'package:photos/utils/navigation_util.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).advancedSettings,
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (delegateBuildContext, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MenuItemWidget(
                        captionedTextWidget: CaptionedTextWidget(
                          title: S.of(context).machineLearning,
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        trailingWidget: Icon(
                          Icons.chevron_right_outlined,
                          color: colorScheme.strokeBase,
                        ),
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        onTap: () async {
                          // ignore: unawaited_futures
                          routeToPage(
                            context,
                            const MachineLearningSettingsPage(),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      MenuItemWidget(
                        captionedTextWidget: CaptionedTextWidget(
                          title: S.of(context).gallery,
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        trailingWidget: Icon(
                          Icons.chevron_right_outlined,
                          color: colorScheme.strokeBase,
                        ),
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        onTap: () async {
                          // ignore: unawaited_futures
                          routeToPage(
                            context,
                            const GallerySettingsScreen(),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      MenuItemWidget(
                        captionedTextWidget: CaptionedTextWidget(
                          title: S.of(context).maps,
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => userRemoteFlagService.getCachedBoolValue(
                            UserRemoteFlagService.mapEnabled,
                          ),
                          onChanged: () async {
                            final isEnabled =
                                userRemoteFlagService.getCachedBoolValue(
                              UserRemoteFlagService.mapEnabled,
                            );

                            await userRemoteFlagService.setBoolValue(
                              UserRemoteFlagService.mapEnabled,
                              !isEnabled,
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      MenuItemWidget(
                        captionedTextWidget: CaptionedTextWidget(
                          title: S.of(context).crashReporting,
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => SuperLogging.shouldReportCrashes(),
                          onChanged: () async {
                            await SuperLogging.setShouldReportCrashes(
                              !SuperLogging.shouldReportCrashes(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }
}
