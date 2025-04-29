import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SocialSectionWidget extends StatelessWidget {
  const SocialSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.social,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.interests_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;
    final result = UpdateService.instance.getRateDetails();
    final String ratePlace = result.item1;
    final String rateUrl = result.item2;

    final List<Widget> options = [
      sectionOptionSpacing,
      if (PlatformUtil.isMobile()) ...[
        SocialsMenuItemWidget(l10n.rateUsOnStore(ratePlace), rateUrl),
        sectionOptionSpacing,
      ],
      SocialsMenuItemWidget(
        l10n.blog,
        "https://ente.io/blog",
        launchInExternalApp: !Platform.isAndroid,
      ),
      sectionOptionSpacing,
      SocialsMenuItemWidget(
        l10n.merchandise,
        "https://shop.ente.io",
        launchInExternalApp: !Platform.isAndroid,
      ),
      const SocialsMenuItemWidget("Mastodon", "https://fosstodon.org/@ente"),
      sectionOptionSpacing,
      const SocialsMenuItemWidget("Twitter", "https://twitter.com/enteio"),
      sectionOptionSpacing,
      const SocialsMenuItemWidget("Matrix", "https://ente.io/matrix"),
      sectionOptionSpacing,
      const SocialsMenuItemWidget("Discord", "https://ente.io/discord"),
      sectionOptionSpacing,
      const SocialsMenuItemWidget("Reddit", "https://reddit.com/r/enteio"),
      sectionOptionSpacing,
    ];
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
