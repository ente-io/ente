import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/hide_shared_items_from_home_gallery_event.dart";
import "package:photos/events/swipe_to_select_enabled_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/viewer/gallery/gallery_group_type_picker_page.dart";
import "package:photos/ui/viewer/gallery/photo_grid_size_picker_page.dart";

class GallerySettingsScreen extends StatefulWidget {
  final bool fromGalleryLayoutSettingsCTA;
  const GallerySettingsScreen({
    super.key,
    required this.fromGalleryLayoutSettingsCTA,
  });

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
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).gallery,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).photoGridSize,
                        trailingWidget: Text(
                          _photoGridSize.toString(),
                          style: textTheme.small,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await routeToPage(
                            context,
                            const PhotoGridSizePickerPage(),
                          );
                          setState(() {
                            _photoGridSize = localSettings.getPhotoGridSize();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).groupBy,
                        trailingWidget: Text(
                          _groupType,
                          style: textTheme.small,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await routeToPage(
                            context,
                            const GalleryGroupTypePickerPage(),
                          );
                          setState(() {
                            _groupType =
                                localSettings.getGalleryGroupType().name;
                          });
                        },
                      ),
                      if (!widget.fromGalleryLayoutSettingsCTA) ...[
                        const SizedBox(height: 8),
                        MenuItemWidgetNew(
                          title: AppLocalizations.of(context)
                              .hideSharedItemsFromHomeGallery,
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
                        const SizedBox(height: 8),
                        MenuItemWidgetNew(
                          title: AppLocalizations.of(context).swipeToSelect,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => localSettings.isSwipeToSelectEnabled,
                            onChanged: () async {
                              final prevSetting =
                                  localSettings.isSwipeToSelectEnabled;
                              await localSettings
                                  .setSwipeToSelectEnabled(!prevSetting);

                              Bus.instance.fire(
                                SwipeToSelectEnabledEvent(!prevSetting),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
