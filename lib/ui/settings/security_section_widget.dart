// @dart=2.9

import 'dart:async';
import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/two_factor_status_change_event.dart';
import 'package:photos/services/local_authentication_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/account/sessions_page.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/settings_text_item.dart';

class SecuritySectionWidget extends StatefulWidget {
  const SecuritySectionWidget({Key key}) : super(key: key);

  @override
  State<SecuritySectionWidget> createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  final _config = Configuration.instance;

  StreamSubscription<TwoFactorStatusChangeEvent> _twoFactorStatusChangeEvent;
  final expandableController = ExpandableController(initialExpanded: false);

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
    expandableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          text: "Security",
          makeTextBold: true,
        ),
        isHeaderOfExpansion: true,
        leadingIcon: Icons.local_police_outlined,
        trailingIcon: Icons.expand_more,
        menuItemColor:
            Theme.of(context).colorScheme.enteTheme.colorScheme.fillFaint,
        expandableController: expandableController,
      ),
      collapsed: const SizedBox.shrink(),
      expanded: _getSectionOptions(context),
      theme: getExpandableTheme(context),
      controller: expandableController,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final List<Widget> children = [];
    if (_config.hasConfiguredAccount()) {
      children.addAll(
        [
          const Padding(padding: EdgeInsets.all(2)),
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Two-factor",
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                FutureBuilder(
                  future: UserService.instance.fetchTwoFactorStatus(),
                  builder: (_, snapshot) {
                    if (snapshot.hasData) {
                      return Switch.adaptive(
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
                      );
                    } else if (snapshot.hasError) {
                      return Icon(
                        Icons.error_outline,
                        color: Colors.white.withOpacity(0.8),
                      );
                    }
                    return const EnteLoadingWidget();
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }
    children.addAll([
      sectionOptionDivider,
      SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Lockscreen",
              style: Theme.of(context).textTheme.subtitle1,
            ),
            Switch.adaptive(
              value: _config.shouldShowLockScreen(),
              onChanged: (value) async {
                final hasAuthenticated = await LocalAuthenticationService
                    .instance
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
          ],
        ),
      ),
    ]);
    if (Platform.isAndroid) {
      children.addAll(
        [
          sectionOptionDivider,
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hide from recents",
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Switch.adaptive(
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .defaultTextColor,
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .defaultTextColor,
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
              ],
            ),
          ),
        ],
      );
    }
    children.addAll([
      sectionOptionDivider,
      GestureDetector(
        behavior: HitTestBehavior.translucent,
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
        child: const SettingsTextItem(
          text: "Active sessions",
          icon: Icons.navigate_next,
        ),
      ),
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
