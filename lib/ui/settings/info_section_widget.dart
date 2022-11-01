// @dart=2.9

import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/ui/common/web_page.dart';
import 'package:ente_auth/ui/settings/app_update_dialog.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/ui/settings/settings_section_title.dart';
import 'package:ente_auth/ui/settings/settings_text_item.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoSectionWidget extends StatelessWidget {
  const InfoSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: const SettingsSectionTitle("About"),
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const WebPage("FAQ", "https://ente.io/faq");
                },
              ),
            );
          },
          child: const SettingsTextItem(text: "FAQ", icon: Icons.navigate_next),
        ),
        sectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const WebPage("terms", "https://ente.io/terms");
                },
              ),
            );
          },
          child:
              const SettingsTextItem(text: "Terms", icon: Icons.navigate_next),
        ),
        sectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const WebPage("privacy", "https://ente.io/privacy");
                },
              ),
            );
          },
          child: const SettingsTextItem(
            text: "Privacy",
            icon: Icons.navigate_next,
          ),
        ),
        sectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            launchUrl(Uri.parse("https://github.com/ente-io/frame"));
          },
          child: const SettingsTextItem(
            text: "Source code",
            icon: Icons.navigate_next,
          ),
        ),
        sectionOptionDivider,
        UpdateService.instance.isIndependent()
            ? Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () async {
                      final dialog =
                          createProgressDialog(context, "Checking...");
                      await dialog.show();
                      final shouldUpdate =
                          await UpdateService.instance.shouldUpdate();
                      await dialog.hide();
                      if (shouldUpdate) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AppUpdateDialog(
                              UpdateService.instance.getLatestVersionInfo(),
                            );
                          },
                          barrierColor: Colors.black.withOpacity(0.85),
                        );
                      } else {
                        showToast(context, "You are on the latest version");
                      }
                    },
                    child: const SettingsTextItem(
                      text: "Check for updates",
                      icon: Icons.navigate_next,
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
