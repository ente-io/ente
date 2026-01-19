import "dart:io";

import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/tools/app_lock.dart";
import "package:photos/utils/lock_screen_settings.dart";

class LockScreenOptions extends StatefulWidget {
  const LockScreenOptions({super.key});

  @override
  State<LockScreenOptions> createState() => _LockScreenOptionsState();
}

class _LockScreenOptionsState extends State<LockScreenOptions> {
  final Configuration _configuration = Configuration.instance;
  final LockScreenSettings _lockscreenSetting = LockScreenSettings.instance;
  late bool appLock;
  late bool hideAppContent;

  @override
  void initState() {
    super.initState();
    hideAppContent = _lockscreenSetting.getShouldHideAppContent();
    appLock = _configuration.shouldShowSystemLockScreen();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    final bool passwordEnabled = await _lockscreenSetting.isPasswordSet();
    final bool pinEnabled = await _lockscreenSetting.isPinSet();
    final bool shouldShowAppContent =
        _lockscreenSetting.getShouldHideAppContent();
    setState(() {
      hideAppContent = shouldShowAppContent;
      appLock = pinEnabled ||
          passwordEnabled ||
          _configuration.shouldShowSystemLockScreen();
    });
  }

  Future<void> _onToggleSwitch() async {
    AppLock.of(context)!.setEnabled(!appLock);
    await _configuration.setSystemLockScreen(!appLock);
    await _lockscreenSetting.removePinAndPassword();
    setState(() {
      _initializeSettings();
      appLock = !appLock;
    });
  }

  Future<void> _tapHideContent() async {
    setState(() {
      hideAppContent = !hideAppContent;
    });
    await _lockscreenSetting.setHideAppContent(
      hideAppContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Figma colors: Light #FAFAFA, Dark #161616
    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                AppLocalizations.of(context).appLock,
                style: textTheme.body.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).appLock,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => appLock,
                          onChanged: () => _onToggleSwitch(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          AppLocalizations.of(context).appLockDescriptions,
                          style: textTheme.mini.copyWith(
                            color: colorScheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).hideContent,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => hideAppContent,
                          onChanged: () => _tapHideContent(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          Platform.isAndroid
                              ? AppLocalizations.of(context)
                                  .hideContentDescriptionAndroid
                              : AppLocalizations.of(context)
                                  .hideContentDescriptionIos,
                          style: textTheme.mini.copyWith(
                            color: colorScheme.textMuted,
                          ),
                        ),
                      ),
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
