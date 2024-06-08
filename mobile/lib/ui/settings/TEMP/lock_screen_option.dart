import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/local_authentication_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/settings/TEMP/lock_screen_option_password.dart";
import "package:photos/ui/settings/TEMP/lock_screen_option_pin.dart";

class LockScreenOption extends StatefulWidget {
  const LockScreenOption({super.key});

  @override
  State<LockScreenOption> createState() => _LockScreenOptionState();
}

class _LockScreenOptionState extends State<LockScreenOption> {
  final Configuration _configuration = Configuration.instance;
  bool? appLock;
  bool isPinEnabled = false;
  bool isPasswordEnabled = false;

  @override
  void initState() {
    isPasswordEnabled = _configuration.isPasswordSet();
    isPinEnabled = _configuration.isPinSet();
    appLock = isPinEnabled || isPasswordEnabled;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
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
                              isTopBorderRadiusRemoved: false,
                              isBottomBorderRadiusRemoved: false,
                              menuItemColor: colorScheme.fillFaint,
                              trailingWidget: ToggleSwitchWidget(
                                value: () => appLock!,
                                onChanged: () async {
                                  bool result;
                                  if ((isPinEnabled || isPasswordEnabled) &&
                                      appLock == true) {
                                    result = await LocalAuthenticationService
                                        .instance
                                        .requestEnteAuthForLockScreen(context);
                                    await _configuration.removePinAndPassword();
                                    isPasswordEnabled =
                                        _configuration.isPasswordSet();
                                    isPinEnabled = _configuration.isPinSet();
                                  }
                                  // else if ((isPasswordEnabled ||
                                  //         isPinEnabled) &&
                                  //     appLock == false) {
                                  //   await _configuration.removePinAndPassword();
                                  //   result = true;
                                  // }
                                  else {
                                    result = await LocalAuthenticationService
                                        .instance
                                        .requestLocalAuthForLockScreen(
                                      context,
                                      !_configuration.shouldShowLockScreen(),
                                      S
                                          .of(context)
                                          .authToChangeLockscreenSetting,
                                      S.of(context).lockScreenEnablePreSteps,
                                    );
                                    await _configuration.removePinAndPassword();
                                    isPasswordEnabled =
                                        _configuration.isPasswordSet();
                                    isPinEnabled = _configuration.isPinSet();
                                  }
                                  setState(() {
                                    if (result) {
                                      appLock = !appLock!;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        appLock!
                            ? Column(
                                children: [
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  MenuItemWidget(
                                    captionedTextWidget:
                                        const CaptionedTextWidget(
                                      title: 'Device Lock',
                                    ),
                                    alignCaptionedTextToLeft: true,
                                    isTopBorderRadiusRemoved: false,
                                    isBottomBorderRadiusRemoved: true,
                                    menuItemColor: colorScheme.fillFaint,
                                    trailingIconIsMuted: true,
                                    trailingIcon: Icons.chevron_right_outlined,
                                    onTap: () async {
                                      setState(() {
                                        _configuration.removePinAndPassword();
                                        isPasswordEnabled =
                                            _configuration.isPasswordSet();
                                        isPinEnabled =
                                            _configuration.isPinSet();
                                      });
                                    },
                                  ),
                                  DividerWidget(
                                    dividerType: DividerType.menuNoIcon,
                                    bgColor: colorScheme.fillFaint,
                                  ),
                                  MenuItemWidget(
                                    captionedTextWidget:
                                        const CaptionedTextWidget(
                                      title: 'PIN lock',
                                    ),
                                    alignCaptionedTextToLeft: true,
                                    isTopBorderRadiusRemoved: true,
                                    isBottomBorderRadiusRemoved: true,
                                    menuItemColor: colorScheme.fillFaint,
                                    trailingIconIsMuted: true,
                                    trailingIcon: Icons.chevron_right_outlined,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (BuildContext context) {
                                            return const LockScreenOptionPin();
                                          },
                                        ),
                                      );
                                      setState(() {
                                        isPasswordEnabled =
                                            _configuration.isPasswordSet();
                                        isPinEnabled =
                                            _configuration.isPinSet();
                                        appLock =
                                            isPinEnabled || isPasswordEnabled;
                                      });
                                    },
                                  ),
                                  DividerWidget(
                                    dividerType: DividerType.menuNoIcon,
                                    bgColor: colorScheme.fillFaint,
                                  ),
                                  MenuItemWidget(
                                    captionedTextWidget:
                                        const CaptionedTextWidget(
                                      title: 'Password lock',
                                    ),
                                    alignCaptionedTextToLeft: true,
                                    isTopBorderRadiusRemoved: true,
                                    isBottomBorderRadiusRemoved: false,
                                    menuItemColor: colorScheme.fillFaint,
                                    trailingIconIsMuted: true,
                                    trailingIcon: Icons.chevron_right_outlined,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (BuildContext context) {
                                            return const LockScreenOptionPassword();
                                          },
                                        ),
                                      );
                                      setState(() {
                                        isPasswordEnabled =
                                            _configuration.isPasswordSet();
                                        isPinEnabled =
                                            _configuration.isPinSet();
                                        appLock =
                                            isPinEnabled || isPasswordEnabled;
                                      });
                                    },
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
