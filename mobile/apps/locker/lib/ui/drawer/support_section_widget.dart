import 'dart:io';

import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_utils/email_util.dart";
import 'package:flutter/material.dart';
import "package:locker/core/constants.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:locker/ui/drawer/about_section_widget.dart";
import "package:locker/ui/drawer/common_settings.dart";
import "package:url_launcher/url_launcher_string.dart";

class SupportSectionWidget extends StatelessWidget {
  const SupportSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: context.l10n.support,
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
            title: context.l10n.contactSupport,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          onTap: () async {
            await sendEmail(context, to: supportEmail);
          },
        ),
        sectionOptionSpacing,
        AboutMenuItemWidget(
          title: context.l10n.help,
          url: "https://ente.io/help",
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: context.l10n.suggestFeatures,
          ),
          trailingIcon: Icons.chevron_right_outlined,
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
            title: context.l10n.reportABug,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          onTap: () async {
            await sendLogs(
              context,
              "support@ente.io",
              dialogBody: context.l10n.logsDialogBodyLocker,
            );
          },
          onLongPress: () async {
            final zipFilePath = await getZippedLogsFile();
            await shareLogs(context, bugsEmail, zipFilePath);
          },
        ),
        sectionOptionSpacing,
      ],
    );
  }
}
