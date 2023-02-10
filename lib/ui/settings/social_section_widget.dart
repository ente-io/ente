import 'package:flutter/material.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SocialSectionWidget extends StatelessWidget {
  const SocialSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "Social",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.interests_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final List<Widget> options = [];
    final result = UpdateService.instance.getRateDetails();
    final String ratePlace = result.item1;
    final String rateUrl = result.item2;
    options.addAll(
      [
        SocialsMenuItemWidget("Rate us on $ratePlace", rateUrl),
        sectionOptionSpacing,
      ],
    );
    options.addAll(
      [
        const SocialsMenuItemWidget("Blog", "https://ente.io/blog"),
        sectionOptionSpacing,
        const SocialsMenuItemWidget("Merchandise", "https://shop.ente.io"),
        sectionOptionSpacing,
        const SocialsMenuItemWidget("Twitter", "https://twitter.com/enteio"),
        sectionOptionSpacing,
        const SocialsMenuItemWidget("Mastodon", "https://mstdn.social/@ente"),
        sectionOptionSpacing,
        const SocialsMenuItemWidget(
          "Matrix",
          "https://ente.io/matrix/",
        ),
        sectionOptionSpacing,
        const SocialsMenuItemWidget("Discord", "https://ente.io/discord"),
        sectionOptionSpacing,
        const SocialsMenuItemWidget("Reddit", "https://reddit.com/r/enteio"),
        sectionOptionSpacing,
      ],
    );

    return Column(children: options);
  }
}

class SocialsMenuItemWidget extends StatelessWidget {
  final String text;
  final String urlSring;
  const SocialsMenuItemWidget(this.text, this.urlSring, {Key? key})
      : super(key: key);

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
        launchUrlString(urlSring);
      },
    );
  }
}
