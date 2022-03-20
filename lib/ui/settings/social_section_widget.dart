import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialSectionWidget extends StatelessWidget {
  const SocialSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSectionTitle("social"),
        Padding(padding: EdgeInsets.all(4)),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            launch("https://twitter.com/enteio");
          },
          child: SettingsTextItem(text: "twitter", icon: Icons.navigate_next),
        ),
        Divider(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            launch("https://ente.io/discord");
          },
          child: SettingsTextItem(text: "discord", icon: Icons.navigate_next),
        ),
        Divider(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            launch("https://reddit.com/r/enteio");
          },
          child: SettingsTextItem(text: "reddit", icon: Icons.navigate_next),
        ),
        !UpdateService.instance.isIndependent()
            ? Column(
                children: [
                  Divider(height: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (Platform.isAndroid) {
                        launch(
                            "https://play.google.com/store/apps/details?id=io.ente.photos");
                      } else {
                        launch(
                            "https://apps.apple.com/in/app/ente-photos/id1542026904");
                      }
                    },
                    child: SettingsTextItem(
                        text: "rate us! ✨", icon: Icons.navigate_next),
                  ),
                ],
              )
            : Container(),
      ],
    );
  }
}
