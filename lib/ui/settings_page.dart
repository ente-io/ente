import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crisp/crisp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/app_lock.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/ui/recovery_key_dialog.dart';
import 'package:photos/utils/auth_util.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/subscription_page.dart';
import 'package:photos/ui/web_page.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("settings"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    final hasLoggedIn = Configuration.instance.getToken() != null;
    final List<Widget> contents = [];
    if (hasLoggedIn) {
      contents.addAll([
        AccountSettingsWidget(),
        Padding(padding: EdgeInsets.all(12)),
      ]);
    }
    contents.addAll([
      SecuritySectionWidget(),
      Padding(padding: EdgeInsets.all(12)),
      SupportSectionWidget(),
      Padding(padding: EdgeInsets.all(12)),
      InfoSectionWidget(),
    ]);
    contents.add(
      FutureBuilder(
        future: _getAppVersion(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "app version: " + snapshot.data,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            );
          }
          return Container();
        },
      ),
    );
    if (kDebugMode && hasLoggedIn) {
      contents.add(DebugWidget());
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: contents,
        ),
      ),
    );
  }

  static Future<String> _getAppVersion() async {
    var pkgInfo = await PackageInfo.fromPlatform();
    return "${pkgInfo.version}";
  }
}

class AccountSettingsWidget extends StatefulWidget {
  AccountSettingsWidget({Key key}) : super(key: key);

  @override
  AccountSettingsWidgetState createState() => AccountSettingsWidgetState();
}

class AccountSettingsWidgetState extends State<AccountSettingsWidget> {
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

              final dialog = createProgressDialog(context, "please wait...");
              await dialog.show();
              var recoveryKey;
              try {
                recoveryKey = await _getOrCreateRecoveryKey();
                await dialog.hide();
              } catch (e) {
                Logger("SecuritySection").severe(e);
                await dialog.hide();
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
    if (_config.getKeyAttributes().recoveryKeyEncryptedWithMasterKey == null) {
      final keyAttributes = await _config.createNewRecoveryKey();
      await UserService.instance.setRecoveryKey(keyAttributes);
    }
    final keyAttributes = _config.getKeyAttributes();
    final recoveryKey = CryptoUtil.decryptSync(
        Sodium.base642bin(keyAttributes.recoveryKeyEncryptedWithMasterKey),
        key,
        Sodium.base642bin(keyAttributes.recoveryKeyDecryptionNonce));
    return Sodium.bin2hex(recoveryKey);
  }
}

class SettingsSectionTitle extends StatelessWidget {
  final String title;
  const SettingsSectionTitle(this.title, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(children: [
      Padding(padding: EdgeInsets.all(4)),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).accentColor,
          ),
        ),
      ),
      Padding(padding: EdgeInsets.all(4)),
    ]));
  }
}

class SupportSectionWidget extends StatelessWidget {
  const SupportSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: [
        SettingsSectionTitle("support"),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  final endpoint = Configuration.instance.getHttpEndpoint() +
                      "/users/roadmap";
                  final isLoggedIn = Configuration.instance.getToken() != null;
                  final url = isLoggedIn
                      ? endpoint + "?token=" + Configuration.instance.getToken()
                      : ROADMAP_URL;
                  return WebPage("roadmap", url);
                },
              ),
            );
          },
          child: SettingsTextItem(text: "roadmap", icon: Icons.navigate_next),
        ),
        Divider(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            final Email email = Email(
              recipients: ['hey@ente.io'],
              isHTML: false,
            );
            try {
              await FlutterEmailSender.send(email);
            } catch (e) {
              showGenericErrorDialog(context);
            }
          },
          onLongPress: () async {
            showToast("thanks for reporting a bug!");
            final dialog = createProgressDialog(context, "preparing logs...");
            await dialog.show();
            final tempPath = (await getTemporaryDirectory()).path;
            final zipFilePath = tempPath + "/logs.zip";
            final logsDirectory = Directory(tempPath + "/logs");
            var encoder = ZipFileEncoder();
            encoder.create(zipFilePath);
            encoder.addDirectory(logsDirectory);
            encoder.close();
            await dialog.hide();
            final Email email = Email(
              recipients: ['bug@ente.io'],
              attachmentPaths: [zipFilePath],
              isHTML: false,
            );
            try {
              await FlutterEmailSender.send(email);
            } catch (e) {
              return Share.shareFiles([zipFilePath]);
            }
          },
          child: SettingsTextItem(text: "email", icon: Icons.navigate_next),
        ),
        Divider(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return CrispChatPage();
                },
              ),
            );
          },
          child: SettingsTextItem(text: "chat", icon: Icons.navigate_next),
        ),
      ]),
    );
  }
}

class InfoSectionWidget extends StatelessWidget {
  const InfoSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: [
        SettingsSectionTitle("about"),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return WebPage("faq", "https://ente.io/faq");
                },
              ),
            );
          },
          child: SettingsTextItem(text: "faq", icon: Icons.navigate_next),
        ),
        Divider(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return WebPage("terms", "https://ente.io/terms");
                },
              ),
            );
          },
          child: SettingsTextItem(text: "terms", icon: Icons.navigate_next),
        ),
        Divider(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return WebPage("privacy", "https://ente.io/privacy");
                },
              ),
            );
          },
          child: SettingsTextItem(text: "privacy", icon: Icons.navigate_next),
        ),
        Divider(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            launch("https://github.com/ente-io/frame");
          },
          child:
              SettingsTextItem(text: "source code", icon: Icons.navigate_next),
        ),
      ]),
    );
  }
}

class DebugWidget extends StatelessWidget {
  const DebugWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: [
        Padding(padding: EdgeInsets.all(12)),
        SettingsSectionTitle("debug"),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            _showKeyAttributesDialog(context);
          },
          child: SettingsTextItem(
              text: "key attributes", icon: Icons.navigate_next),
        ),
      ]),
    );
  }

  void _showKeyAttributesDialog(BuildContext context) {
    final keyAttributes = Configuration.instance.getKeyAttributes();
    AlertDialog alert = AlertDialog(
      title: Text("key attributes"),
      content: SingleChildScrollView(
        child: Column(children: [
          Text("Key", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(Sodium.bin2base64(Configuration.instance.getKey())),
          Padding(padding: EdgeInsets.all(12)),
          Text("Encrypted Key", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.encryptedKey),
          Padding(padding: EdgeInsets.all(12)),
          Text("Key Decryption Nonce",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.keyDecryptionNonce),
          Padding(padding: EdgeInsets.all(12)),
          Text("KEK Salt", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.kekSalt),
          Padding(padding: EdgeInsets.all(12)),
        ]),
      ),
      actions: [
        FlatButton(
          child: Text("OK"),
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

class SettingsTextItem extends StatelessWidget {
  final String text;
  final IconData icon;
  const SettingsTextItem({
    Key key,
    @required this.text,
    @required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(Platform.isIOS ? 4 : 6)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(alignment: Alignment.centerLeft, child: Text(text)),
            Icon(icon),
          ],
        ),
        Padding(padding: EdgeInsets.all(Platform.isIOS ? 4 : 6)),
      ],
    );
  }
}

class CrispChatPage extends StatefulWidget {
  CrispChatPage({Key key}) : super(key: key);

  @override
  _CrispChatPageState createState() => _CrispChatPageState();
}

class _CrispChatPageState extends State<CrispChatPage> {
  static const websiteID = "86d56ea2-68a2-43f9-8acb-95e06dee42e8";

  @override
  void initState() {
    crisp.initialize(
      websiteId: websiteID,
    );
    crisp.register(
      CrispUser(
        email: Configuration.instance.getEmail(),
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("support chat"),
      ),
      body: CrispView(
        loadingWidget: loadWidget,
      ),
    );
  }
}
