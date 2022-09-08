// @dart=2.9

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/account/delete_account_page.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/utils/navigation_util.dart';

class DangerSectionWidget extends StatefulWidget {
  const DangerSectionWidget({Key key}) : super(key: key);

  @override
  State<DangerSectionWidget> createState() => _DangerSectionWidgetState();
}

class _DangerSectionWidgetState extends State<DangerSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: const SettingsSectionTitle("Exit", color: Colors.red),
      collapsed: Container(),
      expanded: _getSectionOptions(context),
      theme: getExpandableTheme(context),
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _onLogoutTapped();
          },
          child:
              const SettingsTextItem(text: "Logout", icon: Icons.navigate_next),
        ),
        sectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            routeToPage(context, const DeleteAccountPage());
          },
          child: const SettingsTextItem(
            text: "Delete account",
            icon: Icons.navigate_next,
          ),
        ),
      ],
    );
  }

  Future<void> _onLogoutTapped() async {
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
