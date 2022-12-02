// @dart=2.9

import 'package:convert/convert.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/account/change_email_dialog.dart';
import 'package:ente_auth/ui/account/password_entry_page.dart';
import 'package:ente_auth/ui/account/recovery_key_page.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:flutter/material.dart';

class AccountSectionWidget extends StatelessWidget {
  AccountSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "Account",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.account_circle_outlined,
    );
  }

  Column _getSectionOptions(BuildContext context) {
    List<Widget> children = [];
    children.addAll([
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
              recoveryKey =
                  hex.encode(await Configuration.instance.getRecoveryKey());
            } catch (e) {
              showGenericErrorDialog(context);
              return;
            }
            routeToPage(
              context,
              RecoveryKeyPage(
                recoveryKey,
                "OK",
                showAppBar: true,
                onDone: () {},
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
    ]);
    return Column(
      children: children,
    );
  }
}
