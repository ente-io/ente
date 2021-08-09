import 'package:crisp/crisp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/ui/web_page.dart';
import 'package:photos/utils/email_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportSectionWidget extends StatelessWidget {
  const SupportSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSectionTitle("support"),
        Padding(padding: EdgeInsets.all(4)),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            try {
              final Email email = Email(
                recipients: ['hey@ente.io'],
                isHTML: false,
              );
              await FlutterEmailSender.send(email);
            } catch (e) {
              Logger("SupportSection").severe(e);
              launch("mailto:hey@ente.io");
            }
          },
          child: SettingsTextItem(text: "email", icon: Icons.navigate_next),
        ),
        Divider(height: 4),
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
                      : kRoadmapURL;
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
          onTap: () {
            launch("https://reddit.com/r/enteio");
          },
          child: SettingsTextItem(text: "community", icon: Icons.navigate_next),
        ),
        Divider(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            await sendLogs(context, "bug@ente.io");
            showToast("thanks for reporting a bug!");
          },
          child: SettingsTextItem(
              text: "report bug 🐞", icon: Icons.navigate_next),
        ),
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
  CrispMain _crisp;

  @override
  void initState() {
    _crisp = CrispMain(
      websiteId: websiteID,
    );
    _crisp.register(
      user: CrispUser(
        email: Configuration.instance.getUserID().toString() + "@ente.io",
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
        crispMain: _crisp,
        loadingWidget: loadWidget,
      ),
    );
  }
}
