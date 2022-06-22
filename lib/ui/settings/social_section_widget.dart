import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialSectionWidget extends StatelessWidget {
  const SocialSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: SettingsSectionTitle("Social"),
      collapsed: Container(),
      expanded: _getSectionOptions(context),
      theme: getExpandableTheme(context),
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    List<Widget> options = [
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          launch("https://twitter.com/enteio");
        },
        child: SettingsTextItem(text: "Twitter", icon: Icons.navigate_next),
      ),
      sectionOptionDivider,
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          launch("https://ente.io/discord");
        },
        child: SettingsTextItem(text: "Discord", icon: Icons.navigate_next),
      ),
      sectionOptionDivider,
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          launch("https://reddit.com/r/enteio");
        },
        child: SettingsTextItem(text: "Reddit", icon: Icons.navigate_next),
      ),
    ];
    if (!UpdateService.instance.isIndependent()) {
      options.addAll(
        [
          sectionOptionDivider,
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (Platform.isAndroid) {
                launch(
                  "https://play.google.com/store/apps/details?id=io.ente.photos",
                );
              } else {
                launch(
                  "https://apps.apple.com/in/app/ente-photos/id1542026904",
                );
              }
            },
            child: SettingsTextItem(
              text: "Rate us! ✨",
              icon: Icons.navigate_next,
            ),
          )
        ],
      );
    }
    return Column(children: options);
  }
}
