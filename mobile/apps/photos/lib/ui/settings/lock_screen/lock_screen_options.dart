import "dart:io";

import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_auto_lock.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_password.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_pin.dart";
import "package:photos/ui/tools/app_lock.dart";
import "package:photos/utils/lock_screen_settings.dart";
import "package:photos/utils/navigation_util.dart";

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
  late bool hideAppContent;

  @override
  void initState() {
    super.initState();
    hideAppContent = _lockscreenSetting.getShouldHideAppContent();
    autoLockTimeInMilliseconds = _lockscreenSetting.getAutoLockTime();
    _initializeSettings();
    appLock = isPinEnabled ||
        isPasswordEnabled ||
        _configuration.shouldShowSystemLockScreen();
  }

  Future<void> _initializeSettings() async {
    final bool passwordEnabled = await _lockscreenSetting.isPasswordSet();
    final bool pinEnabled = await _lockscreenSetting.isPinSet();
    final bool shouldShowAppContent =
        _lockscreenSetting.getShouldHideAppContent();
    setState(() {
      isPasswordEnabled = passwordEnabled;
      isPinEnabled = pinEnabled;
      hideAppContent = shouldShowAppContent;
    });
  }

  Future<void> _deviceLock() async {
    await _lockscreenSetting.removePinAndPassword();
    await _initializeSettings();
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
        appLock = isPinEnabled ||
            isPasswordEnabled ||
            _configuration.shouldShowSystemLockScreen();
      }
    });
  }

  Future<void> _onAutolock() async {
    await routeToPage(
      context,
      const LockScreenAutoLock(),
    ).then((value) {
      setState(() {
        autoLockTimeInMilliseconds = _lockscreenSetting.getAutoLockTime();
      });
    });
  }

  Future<void> _onToggleSwitch() async {
    AppLock.of(context)!.setEnabled(!appLock);
    await _configuration.setSystemLockScreen(!appLock);
    await _lockscreenSetting.removePinAndPassword();
    if (appLock == true) {
      await _lockscreenSetting.setHideAppContent(false);
    }
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

  String _formatTime(Duration duration) {
    if (duration.inHours != 0) {
      return "in ${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}";
    } else if (duration.inMinutes != 0) {
      return "in ${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}";
    } else if (duration.inSeconds != 0) {
      return "in ${duration.inSeconds} second${duration.inSeconds > 1 ? 's' : ''}";
    } else {
      return AppLocalizations.of(context).immediately;
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
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).appLock,
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
                              captionedTextWidget: CaptionedTextWidget(
                                title: AppLocalizations.of(context).appLock,
                              ),
                              alignCaptionedTextToLeft: true,
                              singleBorderRadius: 8,
                              menuItemColor: colorTheme.fillFaint,
                              trailingWidget: ToggleSwitchWidget(
                                value: () => appLock,
                                onChanged: () => _onToggleSwitch(),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 210),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: !appLock
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        top: 14,
                                        left: 14,
                                        right: 12,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .appLockDescriptions,
                                        style: textTheme.miniFaint,
                                        textAlign: TextAlign.left,
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 24),
                            ),
                          ],
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 210),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: appLock
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MenuItemWidget(
                                      captionedTextWidget: CaptionedTextWidget(
                                        title: AppLocalizations.of(context)
                                            .deviceLock,
                                      ),
                                      surfaceExecutionStates: false,
                                      alignCaptionedTextToLeft: true,
                                      isTopBorderRadiusRemoved: false,
                                      isBottomBorderRadiusRemoved: true,
                                      menuItemColor: colorTheme.fillFaint,
                                      trailingIcon:
                                          !(isPasswordEnabled || isPinEnabled)
                                              ? Icons.check
                                              : null,
                                      trailingIconColor: colorTheme.tabIcon,
                                      onTap: () => _deviceLock(),
                                    ),
                                    DividerWidget(
                                      dividerType: DividerType.menuNoIcon,
                                      bgColor: colorTheme.fillFaint,
                                    ),
                                    MenuItemWidget(
                                      captionedTextWidget: CaptionedTextWidget(
                                        title: AppLocalizations.of(context)
                                            .pinLock,
                                      ),
                                      surfaceExecutionStates: false,
                                      alignCaptionedTextToLeft: true,
                                      isTopBorderRadiusRemoved: true,
                                      isBottomBorderRadiusRemoved: true,
                                      menuItemColor: colorTheme.fillFaint,
                                      trailingIcon:
                                          isPinEnabled ? Icons.check : null,
                                      trailingIconColor: colorTheme.tabIcon,
                                      onTap: () => _pinLock(),
                                    ),
                                    DividerWidget(
                                      dividerType: DividerType.menuNoIcon,
                                      bgColor: colorTheme.fillFaint,
                                    ),
                                    MenuItemWidget(
                                      captionedTextWidget: CaptionedTextWidget(
                                        title: AppLocalizations.of(context)
                                            .passwordLock,
                                      ),
                                      surfaceExecutionStates: false,
                                      alignCaptionedTextToLeft: true,
                                      isTopBorderRadiusRemoved: true,
                                      isBottomBorderRadiusRemoved: false,
                                      menuItemColor: colorTheme.fillFaint,
                                      trailingIcon: isPasswordEnabled
                                          ? Icons.check
                                          : null,
                                      trailingIconColor: colorTheme.tabIcon,
                                      onTap: () => _passwordLock(),
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    MenuItemWidget(
                                      captionedTextWidget: CaptionedTextWidget(
                                        title: AppLocalizations.of(context)
                                            .autoLock,
                                        subTitle: _formatTime(
                                          Duration(
                                            milliseconds:
                                                autoLockTimeInMilliseconds,
                                          ),
                                        ),
                                      ),
                                      surfaceExecutionStates: false,
                                      trailingIcon:
                                          Icons.chevron_right_outlined,
                                      trailingIconIsMuted: true,
                                      alignCaptionedTextToLeft: true,
                                      singleBorderRadius: 8,
                                      menuItemColor: colorTheme.fillFaint,
                                      trailingIconColor: colorTheme.tabIcon,
                                      onTap: () => _onAutolock(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 14,
                                        left: 14,
                                        right: 12,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .autoLockFeatureDescription,
                                        style: textTheme.miniFaint,
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    MenuItemWidget(
                                      captionedTextWidget: CaptionedTextWidget(
                                        title: AppLocalizations.of(context)
                                            .hideContent,
                                      ),
                                      alignCaptionedTextToLeft: true,
                                      singleBorderRadius: 8,
                                      menuItemColor: colorTheme.fillFaint,
                                      trailingWidget: ToggleSwitchWidget(
                                        value: () => hideAppContent,
                                        onChanged: () => _tapHideContent(),
                                      ),
                                      trailingIconColor: colorTheme.tabIcon,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 14,
                                        left: 14,
                                        right: 12,
                                      ),
                                      child: Text(
                                        Platform.isAndroid
                                            ? AppLocalizations.of(context)
                                                .hideContentDescriptionAndroid
                                            : AppLocalizations.of(context)
                                                .hideContentDescriptionIos,
                                        style: textTheme.miniFaint,
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                )
                              : Container(),
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
