import "dart:io";

import "package:ente_components/ente_components.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/settings/lock_screen_settings.dart";
import "package:photos/ui/settings/components/settings_item.dart";
import "package:photos/ui/settings/components/settings_page_scaffold.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_auto_lock.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_password.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_pin.dart";
import "package:photos/ui/tools/app_lock.dart";

class LockScreenOptions extends StatefulWidget {
  const LockScreenOptions({super.key});

  @override
  State<LockScreenOptions> createState() => _LockScreenOptionsState();
}

enum LockType { device, pin, password }

class _LockScreenOptionsState extends State<LockScreenOptions> {
  final LockScreenSettings _lockscreenSetting = LockScreenSettings.instance;
  late bool appLock;
  late bool hideAppContent;
  LockType _currentLockType = LockType.device;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    hideAppContent = _lockscreenSetting.getShouldHideAppContent();
    appLock = _lockscreenSetting.appLockEnabledCached;
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    final bool passwordEnabled = await _lockscreenSetting.isPasswordSet();
    final bool pinEnabled = await _lockscreenSetting.isPinSet();
    final bool shouldShowAppContent = _lockscreenSetting
        .getShouldHideAppContent();

    LockType lockType = LockType.device;
    if (pinEnabled) {
      lockType = LockType.pin;
    } else if (passwordEnabled) {
      lockType = LockType.password;
    }

    final bool isAppLockEnabled =
        pinEnabled ||
        passwordEnabled ||
        _lockscreenSetting.shouldShowSystemLockScreen();

    setState(() {
      hideAppContent = shouldShowAppContent;
      _currentLockType = lockType;
      appLock = isAppLockEnabled;
      _isInitialized = true;
    });
    await _lockscreenSetting.setAppLockEnabledCached(isAppLockEnabled);
  }

  Future<void> _onToggleSwitch() async {
    if (appLock) {
      // Turning off app lock
      AppLock.of(context)!.setEnabled(false);
      await _lockscreenSetting.setSystemLockScreen(false);
      await _lockscreenSetting.removePinAndPassword();
      setState(() {
        appLock = false;
        _currentLockType = LockType.device;
      });
    } else {
      // Turning on app lock - default to device lock
      AppLock.of(context)!.setEnabled(true);
      await _lockscreenSetting.setSystemLockScreen(true);
      setState(() {
        appLock = true;
        _currentLockType = LockType.device;
      });
    }
    await _initializeSettings();
  }

  Future<void> _onSelectDeviceLock() async {
    // Remove any existing PIN/password and use device lock
    await _lockscreenSetting.removePinAndPassword();
    await _lockscreenSetting.setSystemLockScreen(true);
    AppLock.of(context)!.setEnabled(true);
    setState(() {
      _currentLockType = LockType.device;
    });
    await _initializeSettings();
  }

  Future<void> _onSelectPinLock() async {
    final result = await routeToPage(context, const LockScreenPin());
    if (result == true) {
      await _lockscreenSetting.setSystemLockScreen(false);
      setState(() {
        _currentLockType = LockType.pin;
      });
    }
    await _initializeSettings();
  }

  Future<void> _onSelectPasswordLock() async {
    final result = await routeToPage(context, const LockScreenPassword());
    if (result == true) {
      await _lockscreenSetting.setSystemLockScreen(false);
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
    await _lockscreenSetting.setHideAppContent(hideAppContent);
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
    final l10n = AppLocalizations.of(context);
    final colors = context.componentColors;

    return SettingsPageScaffold(
      title: l10n.appLock,
      children: [
        SettingsItem(
          title: l10n.appLock,
          trailing: ToggleSwitchComponent.async(
            value: () => appLock,
            onChanged: _onToggleSwitch,
          ),
        ),
        _description(l10n.appLockDescriptions),
        if (appLock && _isInitialized) ...[
          const SizedBox(height: Spacing.lg),
          MenuGroupComponent(
            items: [
              _lockTypeItem(
                title: l10n.deviceLock,
                lockType: LockType.device,
                onTap: _onSelectDeviceLock,
              ),
              _lockTypeItem(
                title: l10n.pinLock,
                lockType: LockType.pin,
                onTap: _onSelectPinLock,
              ),
              _lockTypeItem(
                title: l10n.passwordLock,
                lockType: LockType.password,
                onTap: _onSelectPasswordLock,
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          SettingsItem(
            title: l10n.autoLock,
            showOnlyLoadingState: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatAutoLockTime(_lockscreenSetting.getAutoLockTime()),
                  style: TextStyles.body.copyWith(color: colors.textLight),
                ),
                const SizedBox(width: Spacing.xs),
                Icon(
                  Icons.chevron_right_outlined,
                  color: colors.textLight,
                  size: IconSizes.medium,
                ),
              ],
            ),
            onTap: _onAutoLockTap,
          ),
          _description(l10n.autoLockFeatureDescription),
        ],
        const SizedBox(height: Spacing.lg),
        SettingsItem(
          title: l10n.hideContent,
          trailing: ToggleSwitchComponent.async(
            value: () => hideAppContent,
            onChanged: _tapHideContent,
          ),
        ),
        _description(
          Platform.isAndroid
              ? l10n.hideContentDescriptionAndroid
              : l10n.hideContentDescriptionIos,
        ),
      ],
    );
  }

  Widget _description(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Text(
        text,
        style: TextStyles.mini.copyWith(
          color: context.componentColors.textLight,
        ),
      ),
    );
  }

  MenuComponent _lockTypeItem({
    required String title,
    required LockType lockType,
    required Future<void> Function() onTap,
  }) {
    final isSelected = _currentLockType == lockType;
    return MenuComponent(
      title: title,
      trailing: isSelected
          ? HugeIcon(
              icon: HugeIcons.strokeRoundedTick02,
              color: context.componentColors.primary,
              size: IconSizes.medium,
            )
          : null,
      showOnlyLoadingState: true,
      onTap: onTap,
    );
  }
}
