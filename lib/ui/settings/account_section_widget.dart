import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/services/local_authentication_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/account/change_email_dialog.dart';
import 'package:photos/ui/account/delete_account_page.dart';
import 'package:photos/ui/account/password_entry_page.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import "package:photos/ui/payment/subscription.dart";
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/utils/dialog_util.dart';
import "package:url_launcher/url_launcher_string.dart";

class AccountSectionWidget extends StatelessWidget {
  const AccountSectionWidget({Key? key}) : super(key: key);

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
            title: "Manage subscription",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            _onManageSubscriptionTapped(context);
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
          showOnlyLoadingState: true,
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
          showOnlyLoadingState: true,
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
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Export your data ",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            launchUrlString("https://ente.io/faq/migration/out-of-ente/");
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Logout",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            _onLogoutTapped(context);
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Delete account",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            final hasAuthenticated = await LocalAuthenticationService.instance
                .requestLocalAuthentication(
              context,
              "Please authenticate to initiate account deletion",
            );
            if (hasAuthenticated) {
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return const DeleteAccountPage();
                    },
                  ),
                ),
              );
            }
          },
        ),
        sectionOptionSpacing,
      ],
    );
  }

  void _onLogoutTapped(BuildContext context) {
    showChoiceActionSheet(
      context,
      title: "Are you sure you want to logout?",
      firstButtonLabel: "Yes, logout",
      isCritical: true,
      firstButtonOnTap: () async {
        await UserService.instance.logout(context);
      },
    );
  }

  void _onManageSubscriptionTapped(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return getSubscriptionPage();
        },
      ),
    );
  }
}
