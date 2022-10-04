// @dart=2.9

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/common/web_page.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/settings/app_update_dialog.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoSectionWidget extends StatefulWidget {
  const InfoSectionWidget({Key key}) : super(key: key);

  @override
  State<InfoSectionWidget> createState() => _InfoSectionWidgetState();
}

class _InfoSectionWidgetState extends State<InfoSectionWidget> {
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
          text: "About",
        ),
        isHeaderOfExpansion: true,
        leadingIcon: Icons.info_outlined,
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
    return Column(
      children: [
        sectionOptionDivider,
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
