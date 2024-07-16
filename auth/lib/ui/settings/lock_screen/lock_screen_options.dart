import "dart:async";

import "package:ente_auth/core/configuration.dart";
import "package:ente_auth/core/event_bus.dart";
import "package:ente_auth/events/app_lock_update_event.dart";
import "package:ente_auth/theme/ente_theme.dart";
import "package:ente_auth/ui/components/captioned_text_widget.dart";
import "package:ente_auth/ui/components/divider_widget.dart";
import "package:ente_auth/ui/components/menu_item_widget.dart";
import "package:ente_auth/ui/components/title_bar_title_widget.dart";
import "package:ente_auth/ui/components/title_bar_widget.dart";
import "package:ente_auth/ui/components/toggle_switch_widget.dart";
import "package:ente_auth/ui/settings/lock_screen/lock_screen_auto_lock.dart";
import "package:ente_auth/ui/settings/lock_screen/lock_screen_password.dart";
import "package:ente_auth/ui/settings/lock_screen/lock_screen_pin.dart";
import "package:ente_auth/ui/tools/app_lock.dart";
import "package:ente_auth/utils/lock_screen_settings.dart";
import "package:ente_auth/utils/navigation_util.dart";
import "package:flutter/material.dart";

class LockScreenOptions extends StatefulWidget {
  const LockScreenOptions({super.key});

  @override
  State<LockScreenOptions> createState() => _LockScreenOptionsState();
}

class _LockScreenOptionsState extends State<LockScreenOptions> {
  final Configuration _configuration = Configuration.instance;
  final LockScreenSettings _lockscreenSetting = LockScreenSettings.instance;
  late bool appLock;
  bool isPinEnabled = false;
  bool isPasswordEnabled = false;
  late int autoLockTimeInMilliseconds;
  @override
  void initState() {
    super.initState();
    autoLockTimeInMilliseconds = _lockscreenSetting.getAutoLockTime();
    _initializeSettings();
    appLock = isPinEnabled ||
        isPasswordEnabled ||
        _configuration.shouldShowSystemLockScreen();
  }

  Future<void> _initializeSettings() async {
    final bool passwordEnabled = await _lockscreenSetting.isPasswordSet();
    final bool pinEnabled = await _lockscreenSetting.isPinSet();
    setState(() {
      isPasswordEnabled = passwordEnabled;
      isPinEnabled = pinEnabled;
    });
  }

  Future<void> _deviceLock() async {
    await _lockscreenSetting.removePinAndPassword();
    await _initializeSettings();
    await _lockscreenSetting.setAppLockType(AppLockUpdateType.device);
    Bus.instance.fire(
      AppLockUpdateEvent(
        AppLockUpdateType.device,
      ),
    );
  }

  Future<void> _pinLock() async {
    final bool result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const LockScreenPin();
        },
      ),
    );
    setState(() {
      _initializeSettings();
      if (result) {
        Bus.instance.fire(
          AppLockUpdateEvent(
            AppLockUpdateType.pin,
          ),
        );
        _lockscreenSetting.setAppLockType(AppLockUpdateType.pin);
        appLock = isPinEnabled ||
            isPasswordEnabled ||
            _configuration.shouldShowSystemLockScreen();
      }
    });
  }

  Future<void> _passwordLock() async {
    final bool result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const LockScreenPassword();
        },
      ),
    );
    setState(() {
      _initializeSettings();
      if (result) {
        Bus.instance.fire(
          AppLockUpdateEvent(
            AppLockUpdateType.password,
          ),
        );
        _lockscreenSetting.setAppLockType(AppLockUpdateType.password);
        appLock = isPinEnabled ||
            isPasswordEnabled ||
            _configuration.shouldShowSystemLockScreen();
      }
    });
  }

  Future<void> _onToggleSwitch() async {
    AppLock.of(context)!.setEnabled(!appLock);
    await _configuration.setSystemLockScreen(!appLock);
    await _lockscreenSetting.removePinAndPassword();
    await _lockscreenSetting.setAppLockType(
      appLock ? AppLockUpdateType.none : AppLockUpdateType.device,
    );
    Bus.instance.fire(
      AppLockUpdateEvent(
        appLock ? AppLockUpdateType.none : AppLockUpdateType.device,
      ),
    );
    setState(() {
      _initializeSettings();
      appLock = !appLock;
    });
  }

  Future<void> _onAutoLock() async {
    await routeToPage(
      context,
      const LockScreenAutoLock(),
    ).then(
      (value) {
        setState(() {
          autoLockTimeInMilliseconds = _lockscreenSetting.getAutoLockTime();
        });
      },
    );
  }

  String _formatTime(Duration duration) {
    if (duration.inHours != 0) {
      return "in ${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}";
    } else if (duration.inMinutes != 0) {
      return "in ${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}";
    } else if (duration.inSeconds != 0) {
      return "in ${duration.inSeconds} second${duration.inSeconds > 1 ? 's' : ''}";
    } else {
      return "Disabled";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          const TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: 'App lock',
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            MenuItemWidget(
                              captionedTextWidget: const CaptionedTextWidget(
                                title: 'App lock',
                              ),
                              alignCaptionedTextToLeft: true,
                              singleBorderRadius: 8,
                              menuItemColor: colorTheme.fillFaint,
                              trailingWidget: ToggleSwitchWidget(
                                value: () => appLock,
                                onChanged: () => _onToggleSwitch(),
                              ),
                            ),
                            !appLock
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      top: 14,
                                      left: 14,
                                      right: 12,
                                    ),
                                    child: Text(
                                      'Choose between your device\'s default lock screen and a custom lock screen with a PIN or password.',
                                      style: textTheme.miniFaint,
                                      textAlign: TextAlign.left,
                                    ),
                                  )
                                : const SizedBox(),
                            const Padding(
                              padding: EdgeInsets.only(top: 24),
                            ),
                          ],
                        ),
                        appLock
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MenuItemWidget(
                                    captionedTextWidget:
                                        const CaptionedTextWidget(
                                      title: "Device lock",
                                    ),
                                    alignCaptionedTextToLeft: true,
                                    isTopBorderRadiusRemoved: false,
                                    isBottomBorderRadiusRemoved: true,
                                    menuItemColor: colorTheme.fillFaint,
                                    trailingIcon:
                                        !(isPasswordEnabled || isPinEnabled)
                                            ? Icons.check
                                            : null,
                                    trailingIconColor: colorTheme.textBase,
                                    onTap: () => _deviceLock(),
                                  ),
                                  DividerWidget(
                                    dividerType: DividerType.menuNoIcon,
                                    bgColor: colorTheme.fillFaint,
                                  ),
                                  MenuItemWidget(
                                    captionedTextWidget:
                                        const CaptionedTextWidget(
                                      title: "Pin lock",
                                    ),
                                    alignCaptionedTextToLeft: true,
                                    isTopBorderRadiusRemoved: true,
                                    isBottomBorderRadiusRemoved: true,
                                    menuItemColor: colorTheme.fillFaint,
                                    trailingIcon:
                                        isPinEnabled ? Icons.check : null,
                                    trailingIconColor: colorTheme.textBase,
                                    onTap: () => _pinLock(),
                                  ),
                                  DividerWidget(
                                    dividerType: DividerType.menuNoIcon,
                                    bgColor: colorTheme.fillFaint,
                                  ),
                                  MenuItemWidget(
                                    captionedTextWidget:
                                        const CaptionedTextWidget(
                                      title: "Password",
                                    ),
                                    alignCaptionedTextToLeft: true,
                                    isTopBorderRadiusRemoved: true,
                                    isBottomBorderRadiusRemoved: false,
                                    menuItemColor: colorTheme.fillFaint,
                                    trailingIcon:
                                        isPasswordEnabled ? Icons.check : null,
                                    trailingIconColor: colorTheme.textBase,
                                    onTap: () => _passwordLock(),
                                  ),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  MenuItemWidget(
                                    captionedTextWidget: CaptionedTextWidget(
                                      title: "Auto lock",
                                      subTitle: _formatTime(
                                        Duration(
                                          milliseconds:
                                              autoLockTimeInMilliseconds,
                                        ),
                                      ),
                                    ),
                                    alignCaptionedTextToLeft: true,
                                    singleBorderRadius: 8,
                                    menuItemColor: colorTheme.fillFaint,
                                    trailingIconColor: colorTheme.textBase,
                                    onTap: () => _onAutoLock(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 14,
                                      left: 14,
                                      right: 12,
                                    ),
                                    child: Text(
                                      "Require ${_lockscreenSetting.getAppLockType()} if away for some time .",
                                      style: textTheme.miniFaint,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              )
                            : Container(),
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
