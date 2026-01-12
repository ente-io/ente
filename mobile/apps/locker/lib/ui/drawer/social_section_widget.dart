import "dart:io";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:url_launcher/url_launcher_string.dart";

class SocialSectionWidget extends StatelessWidget {
  const SocialSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.social,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: HugeIcons.strokeRoundedGlobe,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;

    final List<Widget> options = [
      _SocialsChildItem(
        l10n.blog,
        "https://ente.io/blog",
        launchInExternalApp: !Platform.isAndroid,
      ),
      _SocialsChildItem(
        l10n.merchandise,
        "https://shop.ente.io",
        launchInExternalApp: !Platform.isAndroid,
      ),
      _SocialsChildItem(
        l10n.twitter,
        "https://twitter.com/enteio",
      ),
      _SocialsChildItem(
        l10n.mastodon,
        "https://fosstodon.org/@ente",
      ),
      _SocialsChildItem(
        l10n.discord,
        "https://ente.io/discord",
      ),
      _SocialsChildItem(
        l10n.reddit,
        "https://reddit.com/r/enteio",
      ),
    ];
    return Column(children: options);
  }
}

class _SocialsChildItem extends StatelessWidget {
  final String text;
  final String url;
  final bool launchInExternalApp;

  const _SocialsChildItem(
    this.text,
    this.url, {
    this.launchInExternalApp = true,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableChildItem(
      title: text,
      trailingIcon: Icons.chevron_right,
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
