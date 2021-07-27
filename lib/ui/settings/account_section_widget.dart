import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/ui/subscription_page.dart';
import 'package:photos/utils/data_util.dart';

class AccountSectionWidget extends StatefulWidget {
  AccountSectionWidget({Key key}) : super(key: key);

  @override
  AccountSectionWidgetState createState() => AccountSectionWidgetState();
}

class AccountSectionWidgetState extends State<AccountSectionWidget> {
  String _usage;

  @override
  void initState() {
    _getUsage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
            ? Padding(padding: EdgeInsets.all(8))
            : Padding(padding: EdgeInsets.all(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("total data backed up"),
            SizedBox(
              height: 20,
              child: _usage == null ? loadWidget : Text(_usage),
            ),
          ],
        ),
      ],
    );
  }

  void _getUsage() {
    BillingService.instance.fetchUsage().then((usage) async {
      if (mounted) {
        setState(() {
          _usage = formatBytes(usage);
        });
      }
    });
  }
}
