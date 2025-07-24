import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/hide_shared_items_from_home_gallery_event.dart";
import "package:photos/events/memories_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/memory_home_widget_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:photos/ui/viewer/gallery/gallery_group_type_picker_page.dart";
import "package:photos/ui/viewer/gallery/photo_grid_size_picker_page.dart";
import "package:photos/utils/navigation_util.dart";

class GallerySettingsScreen extends StatefulWidget {
  const GallerySettingsScreen({super.key});

  @override
  State<GallerySettingsScreen> createState() => _GallerySettingsScreenState();
}

class _GallerySettingsScreenState extends State<GallerySettingsScreen> {
  late int _photoGridSize;
  late String _groupType;

  @override
  void initState() {
    super.initState();
    _photoGridSize = localSettings.getPhotoGridSize();
    _groupType = localSettings.getGalleryGroupType().name;
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
              title: S.of(context).gallery,
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
                      GestureDetector(
                        onTap: () {
                          routeToPage(
                            context,
                            const PhotoGridSizePickerPage(),
                          ).then((value) {
                            setState(() {
                              _photoGridSize = localSettings.getPhotoGridSize();
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
                      GestureDetector(
                        onTap: () {
                          routeToPage(
                            context,
                            const GalleryGroupTypePickerPage(),
                          ).then((value) {
                            setState(() {
                              _groupType =
                                  localSettings.getGalleryGroupType().name;
                            });
                          });
                        },
                        child: MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: S.of(context).groupBy,
                            subTitle: _groupType,
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
                          title: S.of(context).showMemories,
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => memoriesCacheService.showAnyMemories,
                          onChanged: () async {
                            await memoriesCacheService.setShowAnyMemories(
                              !memoriesCacheService.showAnyMemories,
                            );
                            if (!memoriesCacheService.showAnyMemories) {
                              unawaited(
                                MemoryHomeWidgetService.instance.clearWidget(),
                              );
                            }
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      memoriesCacheService.curatedMemoriesOption
                          ? MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: S.of(context).curatedMemories,
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              singleBorderRadius: 8,
                              alignCaptionedTextToLeft: true,
                              trailingWidget: ToggleSwitchWidget(
                                value: () =>
                                    localSettings.isSmartMemoriesEnabled,
                                onChanged: () async {
                                  unawaited(_toggleUpdateMemories());
                                },
                              ),
                            )
                          : const SizedBox(),
                      memoriesCacheService.curatedMemoriesOption
                          ? const SizedBox(
                              height: 24,
                            )
                          : const SizedBox(),
                      MenuItemWidget(
                        captionedTextWidget: CaptionedTextWidget(
                          title: S.of(context).hideSharedItemsFromHomeGallery,
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        trailingWidget: ToggleSwitchWidget(
                          value: () =>
                              localSettings.hideSharedItemsFromHomeGallery,
                          onChanged: () async {
                            final prevSetting =
                                localSettings.hideSharedItemsFromHomeGallery;
                            await localSettings
                                .setHideSharedItemsFromHomeGallery(
                              !prevSetting,
                            );

                            Bus.instance.fire(
                              HideSharedItemsFromHomeGalleryEvent(
                                !prevSetting,
                              ),
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

Future<void> _toggleUpdateMemories() async {
  await localSettings.setSmartMemories(
    !localSettings.isSmartMemoriesEnabled,
  );
  await memoriesCacheService.clearMemoriesCache(
    fromDisk: false,
  );
  await memoriesCacheService.getMemories();
  Bus.instance.fire(MemoriesChangedEvent());
}
