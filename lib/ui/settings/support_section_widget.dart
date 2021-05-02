import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crisp/crisp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/ui/web_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:share/share.dart';

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
            showToast("thanks for reporting a bug!");
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
        crispMain: _crisp,
        loadingWidget: loadWidget,
      ),
    );
  }
}
