import 'package:crisp/crisp.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            UsageWidget(),
            SupportSectionWidget(),
          ],
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
          SettingsSectionTitle("BILLING"),
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
          child: Column(
            children: [
              Padding(padding: EdgeInsets.all(4)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text("Email")),
                  Icon(Icons.navigate_next),
                ],
              ),
              Padding(padding: EdgeInsets.all(4)),
            ],
          ),
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
          child: Column(
            children: [
              Padding(padding: EdgeInsets.all(4)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text("Chat")),
                  Icon(Icons.navigate_next),
                ],
              ),
              Padding(padding: EdgeInsets.all(4)),
            ],
          ),
        ),
      ]),
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
