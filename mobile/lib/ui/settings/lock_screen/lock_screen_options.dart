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
import "package:photos/ui/settings/lock_screen/lock_screen_password.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_pin.dart";
import "package:photos/ui/tools/app_lock.dart";
import "package:photos/utils/lock_screen_settings.dart";
import "package:secure_app_switcher/secure_app_switcher.dart";

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
  late bool showAppContent;
  @override
  void initState() {
    super.initState();
    showAppContent = _lockscreenSetting.getShowAppContent();
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

  Future<void> _onToggleSwitch() async {
    AppLock.of(context)!.setEnabled(!appLock);
    await _configuration.setSystemLockScreen(!appLock);
    await _lockscreenSetting.removePinAndPassword();
    setState(() {
      _initializeSettings();
      appLock = !appLock;
    });
  }

  Future<void> _tapShowContent() async {
    setState(() {
      showAppContent = !showAppContent;
    });
    showAppContent ? SecureAppSwitcher.off() : SecureAppSwitcher.on();
    await _lockscreenSetting.shouldShowAppContent(
      showAppContent,
    );
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
                                children: [
                                  MenuItemWidget(
                                    captionedTextWidget: CaptionedTextWidget(
                                      title: S.of(context).deviceLock,
                                    ),
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
                                      title: S.of(context).pinLock,
                                    ),
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
                                      title: S.of(context).passwordLock,
                                    ),
                                    alignCaptionedTextToLeft: true,
                                    isTopBorderRadiusRemoved: true,
                                    isBottomBorderRadiusRemoved: false,
                                    menuItemColor: colorTheme.fillFaint,
                                    trailingIcon:
                                        isPasswordEnabled ? Icons.check : null,
                                    trailingIconColor: colorTheme.tabIcon,
                                    onTap: () => _passwordLock(),
                                  ),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  MenuItemWidget(
                                    captionedTextWidget: CaptionedTextWidget(
                                      title: "App content in Task switcher",
                                      textStyle: textTheme.small.copyWith(
                                        color: colorTheme.textMuted,
                                      ),
                                    ),
                                    alignCaptionedTextToLeft: true,
                                    isBottomBorderRadiusRemoved: true,
                                    menuItemColor: colorTheme.fillFaint,
                                  ),
                                  MenuItemWidget(
                                    captionedTextWidget:
                                        const CaptionedTextWidget(
                                      title: "Show content",
                                    ),
                                    alignCaptionedTextToLeft: true,
                                    isTopBorderRadiusRemoved: true,
                                    menuItemColor: colorTheme.fillFaint,
                                    trailingWidget: ToggleSwitchWidget(
                                      value: () => showAppContent,
                                      onChanged: () => _tapShowContent(),
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
                                      'If disabled app content will be displayed in the task switcher',
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
