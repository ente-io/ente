import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/services/local_authentication_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/account/change_email_dialog.dart';
import 'package:photos/ui/account/password_entry_page.dart';
import 'package:photos/ui/account/recovery_key_page.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';

class AccountSectionWidget extends StatefulWidget {
  const AccountSectionWidget({Key key}) : super(key: key);

  @override
  AccountSectionWidgetState createState() => AccountSectionWidgetState();
}

class AccountSectionWidgetState extends State<AccountSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: const SettingsSectionTitle("Account"),
      collapsed: const SizedBox.shrink(),
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
            final hasAuthenticatedOrNoLocalAuth =
                await LocalAuthenticationService.instance
                    .requestLocalAuthentication(
              context,
              "Please authenticate to view your recovery key",
            );
            if (hasAuthenticatedOrNoLocalAuth) {
              String recoveryKey;
              try {
                recoveryKey = await _getOrCreateRecoveryKey();
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
          child: const SettingsTextItem(
            text: "Recovery key",
            icon: Icons.navigate_next,
          ),
        ),
        sectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            final hasAuthenticatedOrNoLocalAuth =
                await LocalAuthenticationService.instance
                    .requestLocalAuthentication(
              context,
              "Please authenticate to change your email",
            );
            if (hasAuthenticatedOrNoLocalAuth) {
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
          child: const SettingsTextItem(
            text: "Change email",
            icon: Icons.navigate_next,
          ),
        ),
        sectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            final hasAuthenticatedOrNoLocalAuth =
                await LocalAuthenticationService.instance
                    .requestLocalAuthentication(
              context,
              "Please authenticate to change your password",
            );
            if (hasAuthenticatedOrNoLocalAuth) {
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
          child: const SettingsTextItem(
            text: "Change password",
            icon: Icons.navigate_next,
          ),
        ),
      ],
    );
  }

  Future<String> _getOrCreateRecoveryKey() async {
    return Sodium.bin2hex(
      await UserService.instance.getOrCreateRecoveryKey(context),
    );
  }
}
