import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/app_lock.dart';
import 'package:photos/ui/change_email_dialog.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/ui/recovery_key_page.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/utils/auth_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';

class AccountSectionWidget extends StatefulWidget {
  AccountSectionWidget({Key key}) : super(key: key);

  @override
  AccountSectionWidgetState createState() => AccountSectionWidgetState();
}

class AccountSectionWidgetState extends State<AccountSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: SettingsSectionTitle("Account"),
      collapsed: Container(),
      expanded: _getSectionOptions(context),
      theme: getExpandableTheme(context),
    );
  }

  Column _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return getSubscriptionPage();
                },
              ),
            );
          },
          child: SettingsTextItem(
              text: "Subscription plan", icon: Icons.navigate_next),
        ),
        SectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            AppLock.of(context).setEnabled(false);
            String reason = "please authenticate to view your recovery key";
            final result = await requestAuthentication(reason);
            AppLock.of(context)
                .setEnabled(Configuration.instance.shouldShowLockScreen());
            if (!result) {
              showToast(reason);
              return;
            }

            String recoveryKey;
            try {
              recoveryKey = await _getOrCreateRecoveryKey();
            } catch (e) {
              showGenericErrorDialog(context);
              return;
            }
            routeToPage(
                context,
                RecoveryKeyPage(recoveryKey, "OK",
                    showAppBar: true, onDone: () {}));
          },
          child:
              SettingsTextItem(text: "Recovery New", icon: Icons.navigate_next),
        ),
        SectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            AppLock.of(context).setEnabled(false);
            String reason = "please authenticate to change your email";
            final result = await requestAuthentication(reason);
            AppLock.of(context)
                .setEnabled(Configuration.instance.shouldShowLockScreen());
            if (!result) {
              showToast(reason);
              return;
            }
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return ChangeEmailDialog();
              },
              barrierColor: Colors.black.withOpacity(0.85),
              barrierDismissible: false,
            );
          },
          child:
              SettingsTextItem(text: "Change email", icon: Icons.navigate_next),
        ),
        SectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            AppLock.of(context).setEnabled(false);
            String reason = "please authenticate to change your password";
            final result = await requestAuthentication(reason);
            AppLock.of(context)
                .setEnabled(Configuration.instance.shouldShowLockScreen());
            if (!result) {
              showToast(reason);
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
              text: "Change password", icon: Icons.navigate_next),
        ),
      ],
    );
  }

  Future<String> _getOrCreateRecoveryKey() async {
    return Sodium.bin2hex(
        await UserService.instance.getOrCreateRecoveryKey(context));
  }
}
