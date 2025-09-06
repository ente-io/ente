import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
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

class MemoriesSettingsScreen extends StatefulWidget {
  const MemoriesSettingsScreen({
    super.key,
  });

  @override
  State<MemoriesSettingsScreen> createState() => _MemoriesSettingsScreenState();
}

class _MemoriesSettingsScreenState extends State<MemoriesSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).memories,
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
                          title: AppLocalizations.of(context).showMemories,
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
                                title: AppLocalizations.of(context)
                                    .curatedMemories,
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
