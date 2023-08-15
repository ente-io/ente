import 'package:flutter/material.dart';
import "package:photos/core/error-reporting/super_logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/user_remote_flag_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/components/toggle_switch_widget.dart";
import 'package:photos/ui/tools/debug/app_storage_viewer.dart';
import 'package:photos/ui/viewer/gallery/photo_grid_size_picker_page.dart';
import 'package:photos/utils/local_settings.dart';
import 'package:photos/utils/navigation_util.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  late int _photoGridSize;

  @override
  void initState() {
    _photoGridSize = LocalSettings.instance.getPhotoGridSize();
    super.initState();
  }

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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                routeToPage(
                                  context,
                                  const PhotoGridSizePickerPage(),
                                ).then((value) {
                                  setState(() {
                                    _photoGridSize = LocalSettings.instance
                                        .getPhotoGridSize();
                                  });
                                });
                              },
                              child: MenuItemWidget(
                                captionedTextWidget: CaptionedTextWidget(
                                  title: S.of(context).photoGridSize,
                                  subTitle: _photoGridSize.toString(),
                                ),
                                menuItemColor: colorScheme.fillFaint,
                                trailingWidget: Icon(
                                  Icons.chevron_right_outlined,
                                  color: colorScheme.strokeBase,
                                ),
                                singleBorderRadius: 8,
                                alignCaptionedTextToLeft: true,
                                isGestureDetectorDisabled: true,
                              ),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: S.of(context).manageDeviceStorage,
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingWidget: Icon(
                                Icons.chevron_right_outlined,
                                color: colorScheme.strokeBase,
                              ),
                              singleBorderRadius: 8,
                              alignCaptionedTextToLeft: true,
                              onTap: () async {
                                routeToPage(context, const AppStorageViewer());
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
                                value: () => UserRemoteFlagService.instance
                                    .getCachedBoolValue(
                                  UserRemoteFlagService.mapEnabled,
                                ),
                                onChanged: () async {
                                  final isEnabled = UserRemoteFlagService
                                      .instance
                                      .getCachedBoolValue(
                                    UserRemoteFlagService.mapEnabled,
                                  );

                                  await UserRemoteFlagService.instance
                                      .setBoolValue(
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
                            )
                          ],
                        ),
                      ],
                    ),
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
