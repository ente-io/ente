import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/ui/settings/common_settings.dart';
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
    return ExpandablePanel(
      header: SettingsSectionTitle("Support"),
      collapsed: Container(),
      expanded: _getSectionOptions(context),
      theme: getExpandableTheme(context),
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
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
          child: SettingsTextItem(text: "Email", icon: Icons.navigate_next),
        ),
        SectionOptionDivider,
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
          child: SettingsTextItem(text: "Roadmap", icon: Icons.navigate_next),
        ),
        SectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            await sendLogs(context, "report bug", "bug@ente.io");
          },
          child: SettingsTextItem(
              text: "Report bug 🐞", icon: Icons.navigate_next),
        ),
      ],
    );
  }
}
