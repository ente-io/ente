import "dart:io";

import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SocialSectionWidget extends StatelessWidget {
  const SocialSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: AppLocalizations.of(context).social,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.interests_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final List<Widget> options = [];
    final result = updateService.getRateDetails();
    final String ratePlace = result.item1;
    final String rateUrl = result.item2;
    options.addAll(
      [
        sectionOptionSpacing,
        SocialsMenuItemWidget(
          AppLocalizations.of(context).rateUsOnStore(storeName: ratePlace),
          rateUrl,
        ),
        sectionOptionSpacing,
      ],
    );
    options.addAll(
      [
        SocialsMenuItemWidget(
          AppLocalizations.of(context).blog,
          "https://ente.io/blog",
          launchInExternalApp: !Platform.isAndroid,
        ),
        sectionOptionSpacing,
        SocialsMenuItemWidget(
          AppLocalizations.of(context).merchandise,
          "https://shop.ente.io",
          launchInExternalApp: !Platform.isAndroid,
        ),
        sectionOptionSpacing,
        SocialsMenuItemWidget(
          AppLocalizations.of(context).twitter,
          "https://twitter.com/enteio",
        ),
        sectionOptionSpacing,
        SocialsMenuItemWidget(
          AppLocalizations.of(context).mastodon,
          "https://fosstodon.org/@ente",
        ),
        sectionOptionSpacing,
        SocialsMenuItemWidget(
          AppLocalizations.of(context).matrix,
          "https://ente.io/matrix/",
        ),
        sectionOptionSpacing,
        SocialsMenuItemWidget(
          AppLocalizations.of(context).discord,
          "https://ente.io/discord",
        ),
        sectionOptionSpacing,
        SocialsMenuItemWidget(
          AppLocalizations.of(context).reddit,
          "https://reddit.com/r/enteio",
        ),
        sectionOptionSpacing,
      ],
    );

    return Column(children: options);
  }
}

class SocialsMenuItemWidget extends StatelessWidget {
  final String text;
  final String url;
  final bool launchInExternalApp;

  const SocialsMenuItemWidget(
    this.text,
    this.url, {
    super.key,
    this.launchInExternalApp = true,
  });

  @override
  Widget build(BuildContext context) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: text,
      ),
      pressedColor: getEnteColorScheme(context).fillFaint,
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        // ignore: unawaited_futures
        launchUrlString(
          url,
          mode: launchInExternalApp
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault,
        );
      },
    );
  }
}
