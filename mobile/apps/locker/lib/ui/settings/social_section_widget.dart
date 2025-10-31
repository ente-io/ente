import 'dart:io';

import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import 'package:flutter/material.dart';
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:locker/ui/settings/common_settings.dart";
import 'package:url_launcher/url_launcher_string.dart';

class SocialSectionWidget extends StatelessWidget {
  const SocialSectionWidget({super.key});

  static const double _leadingSpace = 52;

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

    final List<Widget> options = [
      sectionOptionSpacing,
      SocialsMenuItemWidget(
        l10n.blog,
        "https://ente.io/blog",
        leadingSpace: _leadingSpace,
        launchInExternalApp: !Platform.isAndroid,
      ),
      sectionOptionSpacing,
      SocialsMenuItemWidget(
        l10n.merchandise,
        "https://shop.ente.io",
        leadingSpace: _leadingSpace,
        launchInExternalApp: !Platform.isAndroid,
      ),
      const SocialsMenuItemWidget(
        "Twitter",
        "https://twitter.com/enteio",
        leadingSpace: _leadingSpace,
      ),
      sectionOptionSpacing,
      const SocialsMenuItemWidget(
        "Mastodon",
        "https://fosstodon.org/@ente",
        leadingSpace: _leadingSpace,
      ),
      sectionOptionSpacing,
      const SocialsMenuItemWidget(
        "Matrix",
        "https://ente.io/matrix",
        leadingSpace: _leadingSpace,
      ),
      sectionOptionSpacing,
      const SocialsMenuItemWidget(
        "Discord",
        "https://ente.io/discord",
        leadingSpace: _leadingSpace,
      ),
      sectionOptionSpacing,
      const SocialsMenuItemWidget(
        "Reddit",
        "https://reddit.com/r/enteio",
        leadingSpace: _leadingSpace,
      ),
      sectionOptionSpacing,
    ];
    return Column(children: options);
  }
}

class SocialsMenuItemWidget extends StatelessWidget {
  final String text;
  final String url;
  final bool launchInExternalApp;
  final double leadingSpace;

  const SocialsMenuItemWidget(
    this.text,
    this.url, {
    super.key,
    this.launchInExternalApp = true,
    required this.leadingSpace,
  });

  @override
  Widget build(BuildContext context) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: text,
        makeTextBold: true,
      ),
      leadingSpace: leadingSpace,
      trailingIcon: Icons.chevron_right_outlined,
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
