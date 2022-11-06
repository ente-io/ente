// @dart=2.9

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/services/local_authentication_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/account/change_email_dialog.dart';
import 'package:photos/ui/account/password_entry_page.dart';
import 'package:photos/ui/account/recovery_key_page.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';

class AccountSectionWidget extends StatelessWidget {
  const AccountSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "Account",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.account_circle_outlined,
    );
  }

  Column _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Recovery key",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
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
                await showGenericErrorDialog(context);
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
            title: "Change email",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            final hasAuthenticated = await LocalAuthenticationService.instance
                .requestLocalAuthentication(
              context,
              "Please authenticate to change your email",
            );
            if (hasAuthenticated) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const ChangeEmailDialog();
                },
                barrierColor: Colors.black.withOpacity(0.85),
                barrierDismissible: false,
              );
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Change password",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            final hasAuthenticated = await LocalAuthenticationService.instance
                .requestLocalAuthentication(
              context,
              "Please authenticate to change your password",
            );
            if (hasAuthenticated) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const PasswordEntryPage(
                      mode: PasswordEntryMode.update,
                    );
                  },
                ),
              );
            }
          },
        ),
        sectionOptionSpacing,
      ],
    );
  }

  Future<String> _getOrCreateRecoveryKey(BuildContext context) async {
    return Sodium.bin2hex(
      await UserService.instance.getOrCreateRecoveryKey(context),
    );
  }
}
