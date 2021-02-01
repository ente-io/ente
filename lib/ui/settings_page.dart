import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crisp/crisp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/subscription_page.dart';
import 'package:photos/ui/web_page.dart';
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
    final contents = [
      BackupSettingsWidget(),
      SupportSectionWidget(),
      InfoSectionWidget(),
    ];
    if (kDebugMode) {
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
}

class BackupSettingsWidget extends StatefulWidget {
  BackupSettingsWidget({Key key}) : super(key: key);

  @override
  BackupSettingsWidgetState createState() => BackupSettingsWidgetState();
}

class BackupSettingsWidgetState extends State<BackupSettingsWidget> {
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
          SettingsSectionTitle("backup"),
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
          Divider(height: 4),
          Padding(padding: EdgeInsets.all(8)),
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
          Padding(padding: EdgeInsets.all(8)),
          Divider(height: 4),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              _showFoldersDialog(context);
            },
            child: SettingsTextItem(
                text: "backed up folders", icon: Icons.navigate_next),
          ),
          Divider(height: 4),
          Padding(padding: EdgeInsets.all(4)),
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
        ],
      ),
    );
  }

  void _showFoldersDialog(BuildContext context) async {
    AlertDialog alert = AlertDialog(
      title: Text("select folders to back up"),
      content: BackedUpFoldersWidget(),
      actions: [
        FlatButton(
          child: Text("OK"),
          onPressed: () {
            Navigator.of(context).pop();
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

  void _getUsage() {
    BillingService.instance.fetchUsageInGBs().then((usage) async {
      if (mounted) {
        setState(() {
          _usageInGBs = usage;
        });
      }
    });
  }
}

class BackedUpFoldersWidget extends StatefulWidget {
  const BackedUpFoldersWidget({
    Key key,
  }) : super(key: key);

  @override
  _BackedUpFoldersWidgetState createState() => _BackedUpFoldersWidgetState();
}

class _BackedUpFoldersWidgetState extends State<BackedUpFoldersWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: FilesDB.instance.getLocalPaths(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          snapshot.data.sort((first, second) {
            return first.toLowerCase().compareTo(second.toLowerCase());
          });
          final backedUpFolders = Configuration.instance.getPathsToBackUp();
          final foldersWidget = List<Row>();
          for (final folder in snapshot.data) {
            foldersWidget.add(Row(children: [
              Checkbox(
                value: backedUpFolders.contains(folder),
                onChanged: (value) async {
                  if (value) {
                    backedUpFolders.add(folder);
                  } else {
                    backedUpFolders.remove(folder);
                  }
                  await Configuration.instance
                      .setPathsToBackUp(backedUpFolders);
                  setState(() {});
                },
              ),
              Text(folder)
            ]));
          }
          final scrollController = ScrollController();
          return Container(
            child: Scrollbar(
              isAlwaysShown: true,
              controller: scrollController,
              child: SingleChildScrollView(
                child: Column(children: foldersWidget),
                controller: scrollController,
              ),
            ),
          );
        }
        return loadWidget;
      },
    );
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
        Padding(padding: EdgeInsets.all(12)),
        SettingsSectionTitle("support"),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return WebPage(
                      "request feature",
                      Configuration.instance.getHttpEndpoint() +
                          "/users/feedback?token=" +
                          Configuration.instance.getToken());
                },
              ),
            );
          },
          child: SettingsTextItem(
              text: "request feature", icon: Icons.navigate_next),
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
        Padding(padding: EdgeInsets.all(12)),
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
              text: "Key Attributes", icon: Icons.navigate_next),
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
          Text("KEK Hash", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.kekHash),
          Padding(padding: EdgeInsets.all(12)),
        ]),
      ),
      actions: [
        FlatButton(
          child: Text("OK"),
          onPressed: () {
            Navigator.of(context).pop();
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
        Padding(padding: EdgeInsets.all(6)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(alignment: Alignment.centerLeft, child: Text(text)),
            Icon(icon),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
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
