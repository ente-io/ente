import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/memories_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/memory_home_widget_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
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
                AppLocalizations.of(context).memories,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).showMemories,
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
                      if (memoriesCacheService.curatedMemoriesOption) ...[
                        const SizedBox(height: 8),
                        MenuItemWidgetNew(
                          title: AppLocalizations.of(context).curatedMemories,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => localSettings.isSmartMemoriesEnabled,
                            onChanged: () async {
                              unawaited(_toggleUpdateMemories());
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
}
