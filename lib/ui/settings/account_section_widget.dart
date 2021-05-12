import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/ui/backup_folder_selection_widget.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/ui/subscription_page.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/dialog_util.dart';

class AccountSectionWidget extends StatefulWidget {
  AccountSectionWidget({Key key}) : super(key: key);

  @override
  AccountSectionWidgetState createState() => AccountSectionWidgetState();
}

class AccountSectionWidgetState extends State<AccountSectionWidget> {
  double _usageInGBs;

  @override
  void initState() {
    _getUsage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          SettingsSectionTitle("account"),
          Padding(
            padding: EdgeInsets.all(4),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return SubscriptionPage();
                  },
                ),
              );
            },
            child: SettingsTextItem(
                text: "subscription plan", icon: Icons.navigate_next),
          ),
          Platform.isIOS
              ? Padding(padding: EdgeInsets.all(2))
              : Padding(padding: EdgeInsets.all(2)),
          Divider(height: 4),
          Platform.isIOS
              ? Padding(padding: EdgeInsets.all(2))
              : Padding(padding: EdgeInsets.all(4)),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: const BackupFolderSelectionWidget("preserve"),
                    backgroundColor: Colors.black.withOpacity(0.8),
                  );
                },
                barrierColor: Colors.black.withOpacity(0.85),
              );
            },
            child: SettingsTextItem(
                text: "backed up folders", icon: Icons.navigate_next),
          ),
          Platform.isIOS
              ? Padding(padding: EdgeInsets.all(2))
              : Padding(padding: EdgeInsets.all(2)),
          Divider(height: 4),
          Platform.isIOS
              ? Padding(padding: EdgeInsets.all(2))
              : Padding(padding: EdgeInsets.all(4)),
          Container(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("backup over mobile data"),
                Switch(
                  value: Configuration.instance.shouldBackupOverMobileData(),
                  onChanged: (value) async {
                    Configuration.instance.setBackupOverMobileData(value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          Platform.isIOS
              ? Padding(padding: EdgeInsets.all(2))
              : Padding(padding: EdgeInsets.all(4)),
          Divider(height: 4),
          Platform.isIOS
              ? Padding(padding: EdgeInsets.all(6))
              : Padding(padding: EdgeInsets.all(8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("total data backed up"),
              Container(
                height: 20,
                child: _usageInGBs == null
                    ? loadWidget
                    : Text(
                        _usageInGBs.toString() + " GB",
                      ),
              ),
            ],
          ),
          Platform.isIOS
              ? Padding(padding: EdgeInsets.all(6))
              : Padding(padding: EdgeInsets.all(8)),
          Divider(height: 4),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              AlertDialog alert = AlertDialog(
                title: Text("logout"),
                content: Text("are you sure you want to logout?"),
                actions: [
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
                  TextButton(
                    child: Text(
                      "yes, logout",
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context, rootNavigator: true).pop('dialog');
                      final dialog =
                          createProgressDialog(context, "logging out...");
                      await dialog.show();
                      await Configuration.instance.logout();
                      await dialog.hide();
                      Navigator.of(context).popUntil((route) => route.isFirst);
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
            },
            child: SettingsTextItem(text: "logout", icon: Icons.navigate_next),
          ),
        ],
      ),
    );
  }

  void _getUsage() {
    BillingService.instance.fetchUsage().then((usage) async {
      if (mounted) {
        setState(() {
          _usageInGBs = convertBytesToGBs(usage);
        });
      }
    });
  }
}
