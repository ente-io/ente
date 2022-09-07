// @dart=2.9

import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SocialSectionWidget extends StatelessWidget {
  const SocialSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: const SettingsSectionTitle("Social"),
      collapsed: Container(),
      expanded: _getSectionOptions(context),
      theme: getExpandableTheme(context),
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final List<Widget> options = [
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          launchUrlString("https://twitter.com/enteio");
        },
        child:
            const SettingsTextItem(text: "Twitter", icon: Icons.navigate_next),
      ),
      sectionOptionDivider,
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          launchUrlString("https://ente.io/discord");
        },
        child:
            const SettingsTextItem(text: "Discord", icon: Icons.navigate_next),
      ),
      sectionOptionDivider,
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          launchUrlString("https://reddit.com/r/enteio");
        },
        child:
            const SettingsTextItem(text: "Reddit", icon: Icons.navigate_next),
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
                launchUrlString(
                  "https://play.google.com/store/apps/details?id=io.ente.photos",
                );
              } else {
                launchUrlString(
                  "https://apps.apple.com/in/app/ente-photos/id1542026904",
                );
              }
            },
            child: const SettingsTextItem(
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
