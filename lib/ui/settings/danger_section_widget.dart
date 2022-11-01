// @dart=2.9

import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/account/delete_account_page.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:flutter/material.dart';

class DangerSectionWidget extends StatelessWidget {
  const DangerSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "Exit",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.logout_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Logout",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () {
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
          onTap: () {
            routeToPage(context, const DeleteAccountPage());
          },
        ),
        sectionOptionSpacing,
      ],
    );
  }

  Future<void> _onLogoutTapped(BuildContext context) async {
    final AlertDialog alert = AlertDialog(
      title: const Text(
        "Logout",
        style: TextStyle(
          color: Colors.red,
        ),
      ),
      content: const Text("Are you sure you want to logout?"),
      actions: [
        TextButton(
          child: const Text(
            "Yes, logout",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            await UserService.instance.logout(context);
          },
        ),
        TextButton(
          child: const Text("No"),
          onPressed: () {
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
