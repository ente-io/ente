import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/hide_shared_items_from_home_gallery_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/memories_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/viewer/gallery/photo_grid_size_picker_page.dart";
import "package:photos/utils/navigation_util.dart";

class GallerySettingsScreen extends StatefulWidget {
  const GallerySettingsScreen({super.key});

  @override
  State<GallerySettingsScreen> createState() => _GallerySettingsScreenState();
}

class _GallerySettingsScreenState extends State<GallerySettingsScreen> {
  late int _photoGridSize;

  @override
  void initState() {
    super.initState();
    _photoGridSize = localSettings.getPhotoGridSize();
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
                      MenuItemWidget(
                        captionedTextWidget: CaptionedTextWidget(
                          title: S.of(context).showMemories,
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => MemoriesService.instance.showMemories,
                          onChanged: () async {
                            unawaited(
                              MemoriesService.instance.setShowMemories(
                                !MemoriesService.instance.showMemories,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
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
