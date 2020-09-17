import 'package:crisp/crisp.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/date_time_util.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    final contents = [
      UsageWidget(),
      SupportSectionWidget(),
    ];
    if (kDebugMode) {
      contents.add(DebugWidget());
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: contents,
        ),
      ),
    );
  }
}

class UsageWidget extends StatefulWidget {
  UsageWidget({Key key}) : super(key: key);

  @override
  UsageWidgetState createState() => UsageWidgetState();
}

class UsageWidgetState extends State<UsageWidget> {
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
          SettingsSectionTitle("BACKUP"),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              _showFoldersDialog(context);
            },
            child: SettingsTextItem(
                text: "Backed up Folders", icon: Icons.navigate_next),
          ),
          Divider(height: 4),
          Padding(padding: EdgeInsets.all(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total data backed up"),
              _usageInGBs == null
                  ? loadWidget
                  : Text(
                      _usageInGBs.toString() + " GB",
                    ),
            ],
          ),
          Padding(padding: EdgeInsets.all(4)),
          Divider(height: 4),
          Padding(padding: EdgeInsets.all(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tentative bill for " + getFullMonth(DateTime.now())),
              _usageInGBs == null ? loadWidget : _getCost(_usageInGBs),
            ],
          )
        ],
      ),
    );
  }

  void _showFoldersDialog(BuildContext context) async {
    AlertDialog alert = AlertDialog(
      title: Text("Select folders to back up"),
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

  Text _getCost(double usageInGBs) {
    return Text("\$" + (usageInGBs * 0.1).toStringAsFixed(2));
  }

  void _getUsage() {
    Dio().get(
      Configuration.instance.getHttpEndpoint() + "/billing/usage",
      queryParameters: {
        "startTime": 0,
        "endTime": DateTime.now().microsecondsSinceEpoch,
        "token": Configuration.instance.getToken(),
      },
    ).catchError((e) async {
      Logger("Settings").severe(e);
    }).then((response) async {
      if (response != null && response.statusCode == 200) {
        final usageInBytes = response.data["usage"];
        if (mounted) {
          setState(() {
            _usageInGBs = double.parse(
                (usageInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2));
          });
        }
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
          final backedUpFolders = Configuration.instance.getFoldersToBackUp();
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
                      .setFoldersToBackUp(backedUpFolders);
                  setState(() {});
                },
              ),
              Text(folder)
            ]));
          }
          return SingleChildScrollView(
            child: Column(children: foldersWidget),
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
        SettingsSectionTitle("SUPPORT"),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            final Email email = Email(
              recipients: ['support@ente.io'],
              isHTML: false,
            );
            await FlutterEmailSender.send(email);
          },
          child: SettingsTextItem(text: "Email", icon: Icons.navigate_next),
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
          child: SettingsTextItem(text: "Chat", icon: Icons.navigate_next),
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
        SettingsSectionTitle("DEBUG"),
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
      title: Text("Key Attributes"),
      content: SingleChildScrollView(
        child: Column(children: [
          Text("Key", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(Configuration.instance.getBase64EncodedKey()),
          Padding(padding: EdgeInsets.all(12)),
          Text("Encrypted Key", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.encryptedKey),
          Padding(padding: EdgeInsets.all(12)),
          Text("Encrypted Key IV",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.encryptedKeyIV),
          Padding(padding: EdgeInsets.all(12)),
          Text("KEK Salt", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.kekSalt),
          Padding(padding: EdgeInsets.all(12)),
          Text("KEK Hash", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.kekHash),
          Padding(padding: EdgeInsets.all(12)),
          Text("KEK Hash Salt", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.kekHashSalt),
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
        Padding(padding: EdgeInsets.all(4)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(alignment: Alignment.centerLeft, child: Text(text)),
            Icon(icon),
          ],
        ),
        Padding(padding: EdgeInsets.all(4)),
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
        title: Text("Support"),
      ),
      body: CrispView(
        loadingWidget: loadWidget,
      ),
    );
  }
}
