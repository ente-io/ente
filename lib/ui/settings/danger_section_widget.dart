import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:url_launcher/url_launcher.dart';

class DangerSectionWidget extends StatefulWidget {
  DangerSectionWidget({Key key}) : super(key: key);

  @override
  _DangerSectionWidgetState createState() => _DangerSectionWidgetState();
}

class _DangerSectionWidgetState extends State<DangerSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSectionTitle("exit", color: Colors.red),
        Padding(
          padding: EdgeInsets.all(4),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _onLogoutTapped();
          },
          child: SettingsTextItem(text: "logout", icon: Icons.navigate_next),
        ),
        Platform.isIOS
            ? Padding(padding: EdgeInsets.all(2))
            : Padding(padding: EdgeInsets.all(2)),
        Divider(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _onDeleteAccountTapped();
          },
          child: SettingsTextItem(
              text: "delete account", icon: Icons.navigate_next),
        ),
      ],
    );
  }

  Future<void> _onDeleteAccountTapped() async {
    AlertDialog alert = AlertDialog(
      title: Text(
        "delete account",
        style: TextStyle(
          color: Colors.red,
        ),
      ),
      content: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "please send an email to ",
            ),
            TextSpan(
              text: "account-deletion@ente.io",
              style: TextStyle(
                color: Colors.orange[300],
              ),
            ),
            TextSpan(
              text:
                  " from your registered email address.\n\nyour request will be processed within 72 hours.",
            ),
          ],
          style: TextStyle(
            height: 1.5,
            fontFamily: 'Ubuntu',
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            "send email",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            try {
              final Email email = Email(
                recipients: ['account-deletion@ente.io'],
                isHTML: false,
              );
              await FlutterEmailSender.send(email);
            } catch (e) {
              launch("mailto:account-deletion@ente.io");
            }
          },
        ),
        TextButton(
          child: Text(
            "ok",
            style: TextStyle(
              color: Colors.white,
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

  Future<void> _onLogoutTapped() async {
    AlertDialog alert = AlertDialog(
      title: Text(
        "logout",
        style: TextStyle(
          color: Colors.red,
        ),
      ),
      content: Text("are you sure you want to logout?"),
      actions: [
        TextButton(
          child: Text(
            "yes, logout",
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
            "no",
            style: TextStyle(
              color: Theme.of(context).buttonColor,
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
