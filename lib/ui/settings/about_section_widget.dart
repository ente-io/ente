// @dart=2.9

import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/common/web_page.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/settings/app_update_dialog.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
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
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            launchUrl(Uri.parse("https://github.com/ente-io/auth"));
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
                    pressedColor: getEnteColorScheme(context).fillFaint,
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
      pressedColor: getEnteColorScheme(context).fillFaint,
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
