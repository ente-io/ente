import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/two_factor_status_change_event.dart';
import 'package:photos/services/local_authentication_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/account/recovery_key_page.dart";
import 'package:photos/ui/account/sessions_page.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import "package:photos/utils/crypto_util.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

class SecuritySectionWidget extends StatefulWidget {
  const SecuritySectionWidget({Key? key}) : super(key: key);

  @override
  State<SecuritySectionWidget> createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  final _config = Configuration.instance;

  late StreamSubscription<TwoFactorStatusChangeEvent>
      _twoFactorStatusChangeEvent;

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
    final Completer completer = Completer();
    final List<Widget> children = [];
    if (_config.hasConfiguredAccount()) {
      children.addAll(
        [
          sectionOptionSpacing,
          MenuItemWidget(
            captionedTextWidget: const CaptionedTextWidget(
              title: "Recovery key",
            ),
            pressedColor: getEnteColorScheme(context).fillFaint,
            trailingIcon: Icons.chevron_right_outlined,
            trailingIconIsMuted: true,
            showOnlyLoadingState: true,
            onTap: () async {
              final hasAuthenticated = await LocalAuthenticationService.instance
                  .requestLocalAuthentication(
                context,
                "Please authenticate to view your recovery key",
              );
              if (hasAuthenticated) {
                String recoveryKey;
                try {
                  recoveryKey = await _getOrCreateRecoveryKey(context);
                } catch (e) {
                  await showGenericErrorDialog(context: context);
                  return;
                }
                unawaited(
                  routeToPage(
                    context,
                    RecoveryKeyPage(
                      recoveryKey,
                      "OK",
                      showAppBar: true,
                      onDone: () {},
                    ),
                  ),
                );
              }
            },
          ),
          sectionOptionSpacing,
          MenuItemWidget(
            captionedTextWidget: const CaptionedTextWidget(
              title: "Two-factor",
            ),
            trailingWidget: ToggleSwitchWidget(
              value: () => UserService.instance.hasEnabledTwoFactor(),
              onChanged: () async {
                final hasAuthenticated = await LocalAuthenticationService
                    .instance
                    .requestLocalAuthentication(
                  context,
                  "Please authenticate to configure two-factor authentication",
                );
                final isTwoFactorEnabled =
                    UserService.instance.hasEnabledTwoFactor();
                if (hasAuthenticated) {
                  if (isTwoFactorEnabled) {
                    await _disableTwoFactor();
                    completer.isCompleted ? null : completer.complete();
                  } else {
                    await UserService.instance
                        .setupTwoFactor(context, completer);
                  }
                  return completer.future;
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
          title: "Lockscreen",
        ),
        trailingWidget: ToggleSwitchWidget(
          value: () => _config.shouldShowLockScreen(),
          onChanged: () async {
            await LocalAuthenticationService.instance
                .requestLocalAuthForLockScreen(
              context,
              !_config.shouldShowLockScreen(),
              "Please authenticate to change lockscreen setting",
              "To enable lockscreen, please setup device passcode or screen lock in your system settings.",
            );
          },
        ),
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          title: "View active sessions",
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        showOnlyLoadingState: true,
        onTap: () async {
          final hasAuthenticated = await LocalAuthenticationService.instance
              .requestLocalAuthentication(
            context,
            "Please authenticate to view your active sessions",
          );
          if (hasAuthenticated) {
            unawaited(
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const SessionsPage();
                  },
                ),
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

  Future<void> _disableTwoFactor() async {
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

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<String> _getOrCreateRecoveryKey(BuildContext context) async {
    return CryptoUtil.bin2hex(
      await UserService.instance.getOrCreateRecoveryKey(context),
    );
  }
}
