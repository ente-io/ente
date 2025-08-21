import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/about_section_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/utils/email_util.dart';
import "package:url_launcher/url_launcher_string.dart";

class SupportSectionWidget extends StatelessWidget {
  const SupportSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: AppLocalizations.of(context).support,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.help_outline_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final String bugsEmail =
        Platform.isAndroid ? "android-bugs@ente.io" : "ios-bugs@ente.io";
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: AppLocalizations.of(context).contactSupport,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await sendEmail(context, to: supportEmail);
          },
        ),
        sectionOptionSpacing,
        AboutMenuItemWidget(
          title: AppLocalizations.of(context).help,
          url: "https://help.ente.io",
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: AppLocalizations.of(context).suggestFeatures,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            // ignore: unawaited_futures
            launchUrlString(
              githubDiscussionsUrl,
              mode: LaunchMode.externalApplication,
            );
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: AppLocalizations.of(context).reportABug,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await sendLogs(
              context,
              AppLocalizations.of(context).reportBug,
              bugsEmail,
            );
          },
          onLongPress: () async {
            final zipFilePath = await getZippedLogsFile(context);
            await shareLogs(context, bugsEmail, zipFilePath);
          },
        ),
        sectionOptionSpacing,
      ],
    );
  }
}
