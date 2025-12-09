import "package:ente_utils/platform_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:url_launcher/url_launcher.dart";

class AboutSectionWidget extends StatelessWidget {
  const AboutSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: context.l10n.about,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: HugeIcons.strokeRoundedInformationCircle,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        ExpandableChildItem(
          title: context.l10n.weAreOpenSource,
          trailingIcon: Icons.chevron_right,
          onTap: () async {
            // ignore: unawaited_futures
            launchUrl(Uri.parse("https://github.com/ente-io/ente"));
          },
        ),
        ExpandableChildItem(
          title: context.l10n.privacy,
          trailingIcon: Icons.chevron_right,
          onTap: () async {
            await PlatformUtil.openWebView(
              context,
              context.l10n.privacy,
              "https://ente.io/privacy",
            );
          },
        ),
        ExpandableChildItem(
          title: context.l10n.termsOfServicesTitle,
          trailingIcon: Icons.chevron_right,
          onTap: () async {
            await PlatformUtil.openWebView(
              context,
              context.l10n.termsOfServicesTitle,
              "https://ente.io/terms",
            );
          },
        ),
      ],
    );
  }
}
