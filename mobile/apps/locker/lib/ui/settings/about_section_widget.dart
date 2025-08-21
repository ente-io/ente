import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_utils/platform_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:locker/ui/settings/common_settings.dart";
import "package:url_launcher/url_launcher.dart";

class AboutSectionWidget extends StatelessWidget {
  const AboutSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: context.l10n.about,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.info_outline,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: context.l10n.weAreOpenSource,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            // ignore: unawaited_futures
            launchUrl(Uri.parse("https://github.com/ente-io/ente"));
          },
        ),
        sectionOptionSpacing,
        AboutMenuItemWidget(
          title: context.l10n.privacy,
          url: "https://ente.io/privacy",
        ),
        sectionOptionSpacing,
        AboutMenuItemWidget(
          title: context.l10n.termsOfServicesTitle,
          url: "https://ente.io/terms",
        ),
        sectionOptionSpacing,
      ],
    );
  }
}

class AboutMenuItemWidget extends StatelessWidget {
  final String title;
  final String url;
  final String? webPageTitle;
  const AboutMenuItemWidget({
    required this.title,
    required this.url,
    this.webPageTitle,
    super.key,
  });

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
        await PlatformUtil.openWebView(
          context,
          webPageTitle ?? title,
          url,
        );
      },
    );
  }
}
