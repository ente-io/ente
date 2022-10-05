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
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSectionWidget extends StatefulWidget {
  const AboutSectionWidget({Key key}) : super(key: key);

  @override
  State<AboutSectionWidget> createState() => _AboutSectionWidgetState();
}

class _AboutSectionWidgetState extends State<AboutSectionWidget> {
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
          makeTextBold: true,
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
        const AboutMenuItemWidget(
          title: "FAQ",
          webPageTitle: "FAQ",
          url: "https://ente.io/faq",
        ),
        const AboutMenuItemWidget(
          title: "Terms",
          webPageTitle: "terms",
          url: "https://ente.io/terms",
        ),
        const AboutMenuItemWidget(
          title: "Privacy",
          webPageTitle: "privacy",
          url: "https://ente.io/privacy",
        ),
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            text: "Source code",
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            launchUrl(Uri.parse("https://github.com/ente-io/frame"));
          },
        ),
        UpdateService.instance.isIndependent()
            ? Column(
                children: [
                  MenuItemWidget(
                    captionedTextWidget: const CaptionedTextWidget(
                      text: "Check for updates",
                    ),
                    trailingIcon: Icons.chevron_right_outlined,
                    trailingIconIsMuted: true,
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
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

class AboutMenuItemWidget extends StatelessWidget {
  final String title;
  final String webPageTitle;
  final String url;
  const AboutMenuItemWidget({
    @required this.title,
    @required this.webPageTitle,
    @required this.url,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        text: title,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return WebPage(webPageTitle, url);
            },
          ),
        );
      },
    );
  }
}
