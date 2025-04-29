import "dart:async";
import "dart:io";

import "package:ente_auth/core/configuration.dart";
import "package:ente_auth/l10n/l10n.dart";
import "package:ente_auth/services/local_authentication_service.dart";
import "package:ente_auth/theme/ente_theme.dart";
import "package:ente_auth/ui/components/buttons/button_widget.dart";
import "package:ente_auth/ui/components/captioned_text_widget.dart";
import "package:ente_auth/ui/components/dialog_widget.dart";
import "package:ente_auth/ui/components/divider_widget.dart";
import "package:ente_auth/ui/components/menu_item_widget.dart";
import "package:ente_auth/ui/components/models/button_type.dart";
import "package:ente_auth/ui/components/title_bar_title_widget.dart";
import "package:ente_auth/ui/components/title_bar_widget.dart";
import "package:ente_auth/ui/components/toggle_switch_widget.dart";
import "package:ente_auth/ui/settings/lock_screen/lock_screen_auto_lock.dart";
import "package:ente_auth/ui/settings/lock_screen/lock_screen_password.dart";
import "package:ente_auth/ui/settings/lock_screen/lock_screen_pin.dart";
import "package:ente_auth/ui/tools/app_lock.dart";
import "package:ente_auth/utils/lock_screen_settings.dart";
import "package:ente_auth/utils/navigation_util.dart";
import "package:ente_auth/utils/platform_util.dart";
import "package:flutter/material.dart";

class LockScreenOptions extends StatefulWidget {
  const LockScreenOptions({super.key});

  @override
  State<LockScreenOptions> createState() => _LockScreenOptionsState();
}

class _LockScreenOptionsState extends State<LockScreenOptions> {
  final Configuration _configuration = Configuration.instance;
  final LockScreenSettings _lockscreenSetting = LockScreenSettings.instance;
  late bool appLock = false;
  bool isPinEnabled = false;
  bool isPasswordEnabled = false;
  late int autoLockTimeInMilliseconds;
  late bool hideAppContent;
  late bool isSystemLockEnabled = false;

  @override
  void initState() {
    super.initState();
    hideAppContent = _lockscreenSetting.getShouldHideAppContent();
    autoLockTimeInMilliseconds = _lockscreenSetting.getAutoLockTime();
    _initializeSettings();
    appLock = _lockscreenSetting.getIsAppLockSet();
  }

  Future<void> _initializeSettings() async {
    final bool passwordEnabled = await _lockscreenSetting.isPasswordSet();
    final bool pinEnabled = await _lockscreenSetting.isPinSet();
    final bool shouldHideAppContent =
        _lockscreenSetting.getShouldHideAppContent();
    final bool systemLockEnabled = _configuration.shouldShowSystemLockScreen();
    setState(() {
      isPasswordEnabled = passwordEnabled;
      isPinEnabled = pinEnabled;
      hideAppContent = shouldHideAppContent;
      isSystemLockEnabled = systemLockEnabled;
    });
  }

  Future<void> _deviceLock() async {
    if (await LocalAuthenticationService.instance
        .isLocalAuthSupportedOnDevice()) {
      await _lockscreenSetting.removePinAndPassword();
      await _configuration.setSystemLockScreen(!isSystemLockEnabled);
    } else {
      await showDialogWidget(
        context: context,
        title: context.l10n.noSystemLockFound,
        body: context.l10n.deviceLockEnablePreSteps,
        isDismissible: true,
        buttons: const [
          ButtonWidget(
            buttonType: ButtonType.secondary,
            labelText: "OK",
            isInAlert: true,
          ),
        ],
      );
    }
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

    if (result) {
      await _configuration.setSystemLockScreen(false);
      await _lockscreenSetting.setAppLockEnabled(true);
      setState(() {
        appLock = _lockscreenSetting.getIsAppLockSet();
      });
    }
    await _initializeSettings();
  }

  Future<void> _passwordLock() async {
    final bool result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const LockScreenPassword();
        },
      ),
    );
    if (result) {
      await _configuration.setSystemLockScreen(false);
      setState(() {
        appLock = _lockscreenSetting.getIsAppLockSet();
      });
    }
    await _initializeSettings();
  }

  Future<void> _onToggleSwitch() async {
    AppLock.of(context)!.setEnabled(!appLock);
    if (await LocalAuthenticationService.instance
        .isLocalAuthSupportedOnDevice()) {
      await _configuration.setSystemLockScreen(!appLock);
      await _lockscreenSetting.setAppLockEnabled(!appLock);
    } else {
      await _configuration.setSystemLockScreen(false);
      await _lockscreenSetting.setAppLockEnabled(false);
    }
    await _lockscreenSetting.removePinAndPassword();
    if (PlatformUtil.isMobile()) {
      await _lockscreenSetting.setHideAppContent(!appLock);
      setState(() {
        hideAppContent = _lockscreenSetting.getShouldHideAppContent();
      });
    }
    await _initializeSettings();
    setState(() {
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

  Future<void> _onHideContent() async {
    setState(() {
      hideAppContent = !hideAppContent;
    });
    await _lockscreenSetting.setHideAppContent(hideAppContent);
  }

  String _formatTime(Duration duration) {
    if (duration.inHours != 0) {
      return "in ${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}";
    } else if (duration.inMinutes != 0) {
      return "in ${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}";
    } else if (duration.inSeconds != 0) {
      return "in ${duration.inSeconds} second${duration.inSeconds > 1 ? 's' : ''}";
    } else {
      return context.l10n.immediately;
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
              title: context.l10n.appLock,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: context.l10n.appLock,
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
                                        context.l10n.appLockDescription,
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
                                        title: context.l10n.deviceLock,
                                      ),
                                      surfaceExecutionStates: false,
                                      alignCaptionedTextToLeft: true,
                                      isTopBorderRadiusRemoved: false,
                                      isBottomBorderRadiusRemoved: true,
                                      menuItemColor: colorTheme.fillFaint,
                                      trailingIcon: isSystemLockEnabled
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
                                      captionedTextWidget: CaptionedTextWidget(
                                        title: context.l10n.pinLock,
                                      ),
                                      surfaceExecutionStates: false,
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
                                      captionedTextWidget: CaptionedTextWidget(
                                        title: context.l10n.password,
                                      ),
                                      surfaceExecutionStates: false,
                                      alignCaptionedTextToLeft: true,
                                      isTopBorderRadiusRemoved: true,
                                      isBottomBorderRadiusRemoved: false,
                                      menuItemColor: colorTheme.fillFaint,
                                      trailingIcon: isPasswordEnabled
                                          ? Icons.check
                                          : null,
                                      trailingIconColor: colorTheme.textBase,
                                      onTap: () => _passwordLock(),
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    PlatformUtil.isMobile()
                                        ? MenuItemWidget(
                                            captionedTextWidget:
                                                CaptionedTextWidget(
                                              title: context.l10n.autoLock,
                                              subTitle: _formatTime(
                                                Duration(
                                                  milliseconds:
                                                      autoLockTimeInMilliseconds,
                                                ),
                                              ),
                                            ),
                                            surfaceExecutionStates: false,
                                            alignCaptionedTextToLeft: true,
                                            singleBorderRadius: 8,
                                            menuItemColor: colorTheme.fillFaint,
                                            trailingIconColor:
                                                colorTheme.textBase,
                                            onTap: () => _onAutoLock(),
                                          )
                                        : const SizedBox.shrink(),
                                    PlatformUtil.isMobile()
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 14,
                                              left: 14,
                                              right: 12,
                                            ),
                                            child: Text(
                                              context.l10n
                                                  .autoLockFeatureDescription,
                                              style: textTheme.miniFaint,
                                              textAlign: TextAlign.left,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                    PlatformUtil.isMobile()
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 24),
                                              MenuItemWidget(
                                                captionedTextWidget:
                                                    CaptionedTextWidget(
                                                  title:
                                                      context.l10n.hideContent,
                                                ),
                                                alignCaptionedTextToLeft: true,
                                                singleBorderRadius: 8,
                                                menuItemColor:
                                                    colorTheme.fillFaint,
                                                trailingWidget:
                                                    ToggleSwitchWidget(
                                                  value: () => hideAppContent,
                                                  onChanged: () =>
                                                      _onHideContent(),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 14,
                                                  left: 14,
                                                  right: 12,
                                                ),
                                                child: Text(
                                                  Platform.isAndroid
                                                      ? context.l10n
                                                          .hideContentDescriptionAndroid
                                                      : context.l10n
                                                          .hideContentDescriptioniOS,
                                                  style: textTheme.miniFaint,
                                                  textAlign: TextAlign.left,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ],
                                )
                              : const SizedBox.shrink(),
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
