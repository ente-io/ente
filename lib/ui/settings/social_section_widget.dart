// @dart=2.9

import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SocialSectionWidget extends StatefulWidget {
  const SocialSectionWidget({Key key}) : super(key: key);

  @override
  State<SocialSectionWidget> createState() => _SocialSectionWidgetState();
}

class _SocialSectionWidgetState extends State<SocialSectionWidget> {
  final expandableController = ExpandableController(initialExpanded: false);

  @override
  void dispose() {
    expandableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          text: "Social",
        ),
        isHeaderOfExpansion: true,
        leadingIcon: Icons.interests_outlined,
        trailingIcon: Icons.expand_more,
        menuItemColor:
            Theme.of(context).colorScheme.enteTheme.colorScheme.fillFaint,
        expandableController: expandableController,
      ),
      collapsed: const SizedBox.shrink(),
      expanded: _getSectionOptions(context),
      theme: getExpandableTheme(context),
      controller: expandableController,
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
