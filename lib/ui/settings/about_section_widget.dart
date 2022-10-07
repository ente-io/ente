// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/common/web_page.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/settings/app_update_dialog.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSectionWidget extends StatelessWidget {
  const AboutSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "About",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.info_outline,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        const AboutMenuItemWidget(
          title: "FAQ",
          url: "https://ente.io/faq",
        ),
        sectionOptionSpacing,
        const AboutMenuItemWidget(
          title: "Terms",
          url: "https://ente.io/terms",
        ),
        sectionOptionSpacing,
        const AboutMenuItemWidget(
          title: "Privacy",
          url: "https://ente.io/privacy",
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Source code",
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            launchUrl(Uri.parse("https://github.com/ente-io/frame"));
          },
        ),
        sectionOptionSpacing,
        UpdateService.instance.isIndependent()
            ? Column(
                children: [
                  MenuItemWidget(
                    captionedTextWidget: const CaptionedTextWidget(
                      title: "Check for updates",
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
                  sectionOptionSpacing,
                ],
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

class AboutMenuItemWidget extends StatelessWidget {
  final String title;
  final String url;
  final String webPageTitle;
  const AboutMenuItemWidget({
    @required this.title,
    @required this.url,
    this.webPageTitle,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: title,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return WebPage(webPageTitle ?? title, url);
            },
          ),
        );
      },
    );
  }
}
