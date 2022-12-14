// @dart=2.9

import 'dart:io';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/account/sessions_page.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/toggle_switch_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class SecuritySectionWidget extends StatefulWidget {
  const SecuritySectionWidget({Key key}) : super(key: key);

  @override
  State<SecuritySectionWidget> createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  final _config = Configuration.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
    final l10n = context.l10n;
    final List<Widget> children = [];
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
                          l10n.no,
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
                          l10n.yes,
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
}
