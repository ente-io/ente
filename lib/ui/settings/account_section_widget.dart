import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/ui/recovery_key_dialog.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/ui/subscription_page.dart';
import 'package:photos/utils/auth_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

class AccountSectionWidget extends StatefulWidget {
  AccountSectionWidget({Key key}) : super(key: key);

  @override
  AccountSectionWidgetState createState() => AccountSectionWidgetState();
}

class AccountSectionWidgetState extends State<AccountSectionWidget> {
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
            ? Padding(padding: EdgeInsets.all(2))
            : Padding(padding: EdgeInsets.all(4)),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            final result = await requestAuthentication();
            if (!result) {
              showToast("please authenticate to view your recovery key");
              return;
            }

            String recoveryKey;
            try {
              recoveryKey = await _getOrCreateRecoveryKey();
            } catch (e) {
              showGenericErrorDialog(context);
              return;
            }

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return RecoveryKeyDialog(recoveryKey, "ok", () {});
              },
              barrierColor: Colors.black.withOpacity(0.85),
            );
          },
          child:
              SettingsTextItem(text: "recovery key", icon: Icons.navigate_next),
        ),
        Platform.isIOS
            ? Padding(padding: EdgeInsets.all(2))
            : Padding(padding: EdgeInsets.all(4)),
        Divider(height: 4),
        Platform.isIOS
            ? Padding(padding: EdgeInsets.all(2))
            : Padding(padding: EdgeInsets.all(2)),
        // GestureDetector(
        //   behavior: HitTestBehavior.translucent,
        //   onTap: () async {
        //     final result = await requestAuthentication();
        //     if (!result) {
        //       showToast("please authenticate to change your email");
        //       return;
        //     }
        //     // showDialog
        //   },
        //   child:
        //       SettingsTextItem(text: "change email", icon: Icons.navigate_next),
        // ),
        // Padding(padding: EdgeInsets.all(2)),
        // Divider(height: 4),
        // Platform.isIOS
        //     ? Padding(padding: EdgeInsets.all(2))
        //     : Padding(padding: EdgeInsets.all(4)),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            final result = await requestAuthentication();
            if (!result) {
              showToast("please authenticate to change your password");
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return PasswordEntryPage(
                    mode: PasswordEntryMode.update,
                  );
                },
              ),
            );
          },
          child: SettingsTextItem(
              text: "change password", icon: Icons.navigate_next),
        ),
      ],
    );
  }

  Future<String> _getOrCreateRecoveryKey() async {
    return Sodium.bin2hex(
        await UserService.instance.getOrCreateRecoveryKey(context));
  }
}
