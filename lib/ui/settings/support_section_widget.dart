// @dart=2.9

import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/common/web_page.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/utils/email_util.dart';

class SupportSectionWidget extends StatefulWidget {
  const SupportSectionWidget({Key key}) : super(key: key);

  @override
  State<SupportSectionWidget> createState() => _SupportSectionWidgetState();
}

class _SupportSectionWidgetState extends State<SupportSectionWidget> {
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
          text: "Support",
        ),
        isHeaderOfExpansion: true,
        leadingIcon: Icons.help_outline_outlined,
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
    final String bugsEmail =
        Platform.isAndroid ? "android-bugs@ente.io" : "ios-bugs@ente.io";
    return Column(
      children: [
        sectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            await sendEmail(context, to: supportEmail);
          },
          child:
              const SettingsTextItem(text: "Email", icon: Icons.navigate_next),
        ),
        sectionOptionDivider,
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
                      : roadmapURL;
                  return WebPage("Roadmap", url);
                },
              ),
            );
          },
          child: const SettingsTextItem(
            text: "Roadmap",
            icon: Icons.navigate_next,
          ),
        ),
        sectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            await sendLogs(context, "Report bug", bugsEmail);
          },
          onDoubleTap: () async {
            final zipFilePath = await getZippedLogsFile(context);
            await shareLogs(context, bugsEmail, zipFilePath);
          },
          child: const SettingsTextItem(
            text: "Report bug 🐞",
            icon: Icons.navigate_next,
          ),
        ),
      ],
    );
  }
}
