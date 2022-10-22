// @dart=2.9

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/two_factor_status_change_event.dart';
import 'package:photos/services/local_authentication_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/account/sessions_page.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';

class SecuritySectionWidget extends StatefulWidget {
  const SecuritySectionWidget({Key key}) : super(key: key);

  @override
  State<SecuritySectionWidget> createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  final _config = Configuration.instance;

  StreamSubscription<TwoFactorStatusChangeEvent> _twoFactorStatusChangeEvent;

  @override
  void initState() {
    super.initState();
    _twoFactorStatusChangeEvent =
        Bus.instance.on<TwoFactorStatusChangeEvent>().listen((event) async {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _twoFactorStatusChangeEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "Security",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.local_police_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final List<Widget> children = [];
    if (_config.hasConfiguredAccount()) {
      children.addAll(
        [
          sectionOptionSpacing,
          FutureBuilder(
            future: UserService.instance.fetchTwoFactorStatus(),
            builder: (_, snapshot) {
              return MenuItemWidget(
                captionedTextWidget: const CaptionedTextWidget(
                  title: "Two-factor",
                ),
                trailingSwitch: snapshot.hasData
                    ? ToggleSwitchWidget(
                        value: snapshot.data,
                        onChanged: (value) async {
                          final hasAuthenticated =
                              await LocalAuthenticationService.instance
                                  .requestLocalAuthentication(
                            context,
                            "Please authenticate to configure two-factor authentication",
                          );
                          if (hasAuthenticated) {
                            if (value) {
                              UserService.instance.setupTwoFactor(context);
                            } else {
                              _disableTwoFactor();
                            }
                          }
                        },
                      )
                    : snapshot.hasError
                        ? const Icon(Icons.error_outline_outlined)
                        : const EnteLoadingWidget(),
              );
            },
          ),
          sectionOptionSpacing,
        ],
      );
    }
    children.addAll([
      MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          title: "Lockscreen",
        ),
        trailingSwitch: ToggleSwitchWidget(
          value: _config.shouldShowLockScreen(),
          onChanged: (value) async {
            final hasAuthenticated = await LocalAuthenticationService.instance
                .requestLocalAuthForLockScreen(
              context,
              value,
              "Please authenticate to change lockscreen setting",
              "To enable lockscreen, please setup device passcode or screen lock in your system settings.",
            );
            if (hasAuthenticated) {
              setState(() {});
            }
          },
        ),
      ),
      sectionOptionSpacing,
    ]);
    if (Platform.isAndroid) {
      children.addAll(
        [
          MenuItemWidget(
            captionedTextWidget: const CaptionedTextWidget(
              title: "Hide from recents",
            ),
            trailingSwitch: ToggleSwitchWidget(
              value: _config.shouldHideFromRecents(),
              onChanged: (value) async {
                if (value) {
                  final AlertDialog alert = AlertDialog(
                    title: const Text("Hide from recents?"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Hiding from the task switcher will prevent you from taking screenshots in this app.",
                            style: TextStyle(
                              height: 1.5,
                            ),
                          ),
                          Padding(padding: EdgeInsets.all(8)),
                          Text(
                            "Are you sure?",
                            style: TextStyle(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text(
                          "No",
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.defaultTextColor,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true)
                              .pop('dialog');
                        },
                      ),
                      TextButton(
                        child: Text(
                          "Yes",
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.defaultTextColor,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(context, rootNavigator: true)
                              .pop('dialog');
                          await _config.setShouldHideFromRecents(true);
                          await FlutterWindowManager.addFlags(
                            FlutterWindowManager.FLAG_SECURE,
                          );
                          setState(() {});
                        },
                      ),
                    ],
                  );

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return alert;
                    },
                  );
                } else {
                  await _config.setShouldHideFromRecents(false);
                  await FlutterWindowManager.clearFlags(
                    FlutterWindowManager.FLAG_SECURE,
                  );
                  setState(() {});
                }
              },
            ),
          ),
          sectionOptionSpacing,
        ],
      );
    }
    children.addAll([
      MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          title: "Active sessions",
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          final hasAuthenticated = await LocalAuthenticationService.instance
              .requestLocalAuthentication(
            context,
            "Please authenticate to view your active sessions",
          );
          if (hasAuthenticated) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const SessionsPage();
                },
              ),
            );
          }
        },
      ),
      sectionOptionSpacing,
    ]);
    return Column(
      children: children,
    );
  }

  void _disableTwoFactor() {
    final AlertDialog alert = AlertDialog(
      title: const Text("Disable two-factor"),
      content: const Text(
        "Are you sure you want to disable two-factor authentication?",
      ),
      actions: [
        TextButton(
          child: Text(
            "No",
            style: TextStyle(
              color: Theme.of(context).colorScheme.greenAlternative,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
        TextButton(
          child: const Text(
            "Yes",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () async {
            await UserService.instance.disableTwoFactor(context);
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
