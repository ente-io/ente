// @dart=2.9

import 'dart:io';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/store/code_store.dart';
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
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:share_plus/share_plus.dart';

class AccountSectionWidget extends StatelessWidget {
  final _codeFile = File(
    Configuration.instance.getTempDirectory() + "ente-authenticator-codes.txt",
  );

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
    if (Configuration.instance.getRecoveryKey() != null) {
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
                    Sodium.bin2base64(Configuration.instance.getRecoveryKey());
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
      ]);
    }
    children.addAll([
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
      MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          title: "Export secrets",
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          _showWarningDialog(context);
        },
      ),
      sectionOptionSpacing,
    ]);
    return Column(
      children: children,
    );
  }

  Future<void> _showWarningDialog(BuildContext context) async {
    final AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        "Warning",
        style: Theme.of(context).textTheme.headline6,
      ),
      content: const Text(
        "The exported file contains sensitive information. Please store this safely.",
      ),
      actions: [
        TextButton(
          child: const Text(
            "I understand",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            _exportCodes(context);
          },
        ),
        TextButton(
          child: const Text(
            "Cancel",
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
      barrierColor: Colors.black12,
    );
  }

  Future<void> _exportCodes(BuildContext context) async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      "Please authenticate to export your codes",
    );
    if (!hasAuthenticated) {
      return;
    }
    if (_codeFile.existsSync()) {
      await _codeFile.delete();
    }
    final codes = await CodeStore.instance.getAllCodes();
    String data = "";
    for (final code in codes) {
      data += code.rawData + "\n";
    }
    _codeFile.writeAsStringSync(data);
    await Share.shareFiles([_codeFile.path]);
    Future.delayed(const Duration(seconds: 15), () async {
      if (_codeFile.existsSync()) {
        _codeFile.deleteSync();
      }
    });
  }
}
