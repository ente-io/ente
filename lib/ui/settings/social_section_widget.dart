// @dart=2.9

import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SocialSectionWidget extends StatefulWidget {
  const SocialSectionWidget({Key key}) : super(key: key);

  @override
  State<SocialSectionWidget> createState() => _SocialSectionWidgetState();
}

class _SocialSectionWidgetState extends State<SocialSectionWidget> {
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
          text: "Social",
          makeTextBold: true,
        ),
        isHeaderOfExpansion: true,
        leadingIcon: Icons.interests_outlined,
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
    final List<Widget> options = [
      sectionOptionDivider,
      const SocialsMenuItemWidget("Twitter", "https://twitter.com/enteio"),
      const SocialsMenuItemWidget("Discord", "https://ente.io/discord"),
      const SocialsMenuItemWidget("Reddit", "https://reddit.com/r/enteio"),
    ];
    if (!UpdateService.instance.isIndependent()) {
      options.addAll(
        [
          SocialsMenuItemWidget(
            "Rate us! ✨",
            Platform.isAndroid
                ? "https://play.google.com/store/apps/details?id=io.ente.photos"
                : "https://apps.apple.com/in/app/ente-photos/id1542026904",
          ),
        ],
      );
    }
    return Column(children: options);
  }
}

class SocialsMenuItemWidget extends StatelessWidget {
  final String text;
  final String urlSring;
  const SocialsMenuItemWidget(this.text, this.urlSring, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        text: text,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () {
        launchUrlString(urlSring);
      },
    );
  }
}
