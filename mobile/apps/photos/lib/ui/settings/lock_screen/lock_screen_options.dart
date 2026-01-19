import "dart:io";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_auto_lock.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_password.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_pin.dart";
import "package:photos/ui/tools/app_lock.dart";
import "package:photos/utils/lock_screen_settings.dart";

class LockScreenOptions extends StatefulWidget {
  const LockScreenOptions({super.key});

  @override
  State<LockScreenOptions> createState() => _LockScreenOptionsState();
}

enum LockType { device, pin, password }

class _LockScreenOptionsState extends State<LockScreenOptions> {
  final Configuration _configuration = Configuration.instance;
  final LockScreenSettings _lockscreenSetting = LockScreenSettings.instance;
  late bool appLock;
  late bool hideAppContent;
  LockType _currentLockType = LockType.device;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    hideAppContent = _lockscreenSetting.getShouldHideAppContent();
    appLock = true; // Will be corrected by _initializeSettings()
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    final bool passwordEnabled = await _lockscreenSetting.isPasswordSet();
    final bool pinEnabled = await _lockscreenSetting.isPinSet();
    final bool shouldShowAppContent =
        _lockscreenSetting.getShouldHideAppContent();

    LockType lockType = LockType.device;
    if (pinEnabled) {
      lockType = LockType.pin;
    } else if (passwordEnabled) {
      lockType = LockType.password;
    }

    setState(() {
      hideAppContent = shouldShowAppContent;
      _currentLockType = lockType;
      appLock = pinEnabled ||
          passwordEnabled ||
          _configuration.shouldShowSystemLockScreen();
      _isInitialized = true;
    });
  }

  Future<void> _onToggleSwitch() async {
    if (appLock) {
      // Turning off app lock
      AppLock.of(context)!.setEnabled(false);
      await _configuration.setSystemLockScreen(false);
      await _lockscreenSetting.removePinAndPassword();
      setState(() {
        appLock = false;
        _currentLockType = LockType.device;
      });
    } else {
      // Turning on app lock - default to device lock
      AppLock.of(context)!.setEnabled(true);
      await _configuration.setSystemLockScreen(true);
      setState(() {
        appLock = true;
        _currentLockType = LockType.device;
      });
    }
  }

  Future<void> _onSelectDeviceLock() async {
    // Remove any existing PIN/password and use device lock
    await _lockscreenSetting.removePinAndPassword();
    await _configuration.setSystemLockScreen(true);
    AppLock.of(context)!.setEnabled(true);
    setState(() {
      _currentLockType = LockType.device;
    });
  }

  Future<void> _onSelectPinLock() async {
    final result = await routeToPage(
      context,
      const LockScreenPin(),
    );
    if (result == true) {
      await _configuration.setSystemLockScreen(false);
      setState(() {
        _currentLockType = LockType.pin;
      });
    }
    await _initializeSettings();
  }

  Future<void> _onSelectPasswordLock() async {
    final result = await routeToPage(
      context,
      const LockScreenPassword(),
    );
    if (result == true) {
      await _configuration.setSystemLockScreen(false);
      setState(() {
        _currentLockType = LockType.password;
      });
    }
    await _initializeSettings();
  }

  Future<void> _onAutoLockTap() async {
    await routeToPage(context, const LockScreenAutoLock());
    setState(() {});
  }

  Future<void> _tapHideContent() async {
    setState(() {
      hideAppContent = !hideAppContent;
    });
    await _lockscreenSetting.setHideAppContent(
      hideAppContent,
    );
  }

  String _formatAutoLockTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    if (duration.inMinutes >= 1) {
      return "${duration.inMinutes}m";
    } else if (duration.inSeconds >= 1) {
      return "${duration.inSeconds}s";
    } else {
      return AppLocalizations.of(context).immediately;
    }
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
                      if (appLock && _isInitialized) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MenuItemWidgetNew(
                                title: AppLocalizations.of(context).deviceLock,
                                borderRadius: 0,
                                trailingIcon:
                                    _currentLockType == LockType.device
                                        ? Icons.check
                                        : null,
                                onTap: () async => _onSelectDeviceLock(),
                              ),
                              MenuItemWidgetNew(
                                title: AppLocalizations.of(context).pinLock,
                                borderRadius: 0,
                                trailingIcon: _currentLockType == LockType.pin
                                    ? Icons.check
                                    : null,
                                onTap: () async => _onSelectPinLock(),
                              ),
                              MenuItemWidgetNew(
                                title:
                                    AppLocalizations.of(context).passwordLock,
                                borderRadius: 0,
                                trailingIcon:
                                    _currentLockType == LockType.password
                                        ? Icons.check
                                        : null,
                                onTap: () async => _onSelectPasswordLock(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        MenuItemWidgetNew(
                          title: AppLocalizations.of(context).autoLock,
                          trailingWidget: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatAutoLockTime(
                                  _lockscreenSetting.getAutoLockTime(),
                                ),
                                style: textTheme.small.copyWith(
                                  color: colorScheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                color: colorScheme.strokeMuted,
                              ),
                            ],
                          ),
                          onTap: () async => _onAutoLockTap(),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            AppLocalizations.of(context)
                                .autoLockFeatureDescription,
                            style: textTheme.mini.copyWith(
                              color: colorScheme.textMuted,
                            ),
                          ),
                        ),
                      ],
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
