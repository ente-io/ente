import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/app_lock.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/ui/recovery_key_dialog.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/utils/auth_util.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

class SecuritySectionWidget extends StatefulWidget {
  SecuritySectionWidget({Key key}) : super(key: key);

  @override
  _SecuritySectionWidgetState createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  final _config = Configuration.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    children.addAll([
      SettingsSectionTitle("security"),
    ]);
    if (_config.hasConfiguredAccount()) {
      children.addAll(
        [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              final result = await requestAuthentication();
              if (!result) {
                showToast("please authenticate to view your recovery key");
                return;
              }

              var recoveryKey;
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
            child: SettingsTextItem(
                text: "recovery key", icon: Icons.navigate_next),
          ),
          Platform.isIOS
              ? Padding(padding: EdgeInsets.all(2))
              : Padding(padding: EdgeInsets.all(4)),
          Divider(height: 4),
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
    children.addAll([
      Padding(padding: EdgeInsets.all(2)),
      Divider(height: 4),
      Platform.isIOS
          ? Padding(padding: EdgeInsets.all(2))
          : Padding(padding: EdgeInsets.all(4)),
      Container(
        height: 36,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("lockscreen"),
            Switch(
              value: _config.shouldShowLockScreen(),
              onChanged: (value) async {
                AppLock.of(context).disable();
                final result = await requestAuthentication();
                if (result) {
                  AppLock.of(context).setEnabled(value);
                  _config.setShouldShowLockScreen(value);
                  setState(() {});
                } else {
                  AppLock.of(context)
                      .setEnabled(_config.shouldShowLockScreen());
                }
              },
            ),
          ],
        ),
      ),
    ]);
    if (Platform.isAndroid) {
      children.addAll([
        Padding(padding: EdgeInsets.all(4)),
        Divider(height: 4),
        Padding(padding: EdgeInsets.all(4)),
        Container(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("hide from recents"),
              Switch(
                value: _config.shouldHideFromRecents(),
                onChanged: (value) async {
                  if (value) {
                    AlertDialog alert = AlertDialog(
                      title: Text("hide from recents?"),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "hiding from the task switcher will prevent you from taking screenshots in this app.",
                              style: TextStyle(
                                height: 1.5,
                              ),
                            ),
                            Padding(padding: EdgeInsets.all(8)),
                            Text(
                              "are you sure?",
                              style: TextStyle(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          child:
                              Text("no", style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true)
                                .pop('dialog');
                          },
                        ),
                        TextButton(
                          child: Text("yes",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8))),
                          onPressed: () async {
                            Navigator.of(context, rootNavigator: true)
                                .pop('dialog');
                            await _config.setShouldHideFromRecents(true);
                            await FlutterWindowManager.addFlags(
                                FlutterWindowManager.FLAG_SECURE);
                            setState(() {});
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
                  } else {
                    await _config.setShouldHideFromRecents(false);
                    await FlutterWindowManager.clearFlags(
                        FlutterWindowManager.FLAG_SECURE);
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ),
      ]);
    }
    return Container(
      child: Column(
        children: children,
      ),
    );
  }

  Future<String> _getOrCreateRecoveryKey() async {
    final key = _config.getKey();
    final encryptedRecoveryKey =
        _config.getKeyAttributes().recoveryKeyEncryptedWithMasterKey;
    if (encryptedRecoveryKey == null || encryptedRecoveryKey.isEmpty) {
      final dialog = createProgressDialog(context, "please wait...");
      await dialog.show();
      try {
        final keyAttributes = await _config.createNewRecoveryKey();
        await UserService.instance.setRecoveryKey(keyAttributes);
        await dialog.hide();
      } catch (e, s) {
        await dialog.hide();
        Logger("SecuritySection").severe(e, s);
        throw e;
      }
    }
    final keyAttributes = _config.getKeyAttributes();
    final recoveryKey = CryptoUtil.decryptSync(
        Sodium.base642bin(keyAttributes.recoveryKeyEncryptedWithMasterKey),
        key,
        Sodium.base642bin(keyAttributes.recoveryKeyDecryptionNonce));
    return Sodium.bin2hex(recoveryKey);
  }
}
