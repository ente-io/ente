import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/app_update_dialog.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/ui/web_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoSectionWidget extends StatelessWidget {
  const InfoSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          SettingsSectionTitle("about"),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return WebPage("faq", "https://ente.io/faq");
                  },
                ),
              );
            },
            child: SettingsTextItem(text: "faq", icon: Icons.navigate_next),
          ),
          Divider(height: 4),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return WebPage("terms", "https://ente.io/terms");
                  },
                ),
              );
            },
            child: SettingsTextItem(text: "terms", icon: Icons.navigate_next),
          ),
          Divider(height: 4),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return WebPage("privacy", "https://ente.io/privacy");
                  },
                ),
              );
            },
            child: SettingsTextItem(text: "privacy", icon: Icons.navigate_next),
          ),
          Divider(height: 4),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              launch("https://github.com/ente-io/frame");
            },
            child: SettingsTextItem(
                text: "source code", icon: Icons.navigate_next),
          ),
          UpdateService.instance.isIndependent()
              ? Divider(height: 4)
              : Container(),
          UpdateService.instance.isIndependent()
              ? GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    final dialog = createProgressDialog(context, "checking...");
                    await dialog.show();
                    final shouldUpdate =
                        await UpdateService.instance.shouldUpdate();
                    await dialog.hide();
                    if (shouldUpdate) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AppUpdateDialog(
                                UpdateService.instance.getLatestVersionInfo());
                          });
                    } else {
                      showToast("you are on the latest version");
                    }
                  },
                  child: SettingsTextItem(
                      text: "check for updates", icon: Icons.navigate_next),
                )
              : GestureDetector(
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
                      text: "rate us", icon: Icons.navigate_next),
                ),
        ],
      ),
    );
  }
}
