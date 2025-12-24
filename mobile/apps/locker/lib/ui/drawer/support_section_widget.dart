import "dart:io";

import "package:ente_utils/email_util.dart";
import "package:ente_utils/platform_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/core/constants.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:url_launcher/url_launcher_string.dart";

class SupportSectionWidget extends StatelessWidget {
  const SupportSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: context.l10n.support,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: HugeIcons.strokeRoundedHelpCircle,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final String bugsEmail =
        Platform.isAndroid ? "android-bugs@ente.io" : "ios-bugs@ente.io";
    return Column(
      children: [
        ExpandableChildItem(
          title: context.l10n.contactSupport,
          trailingIcon: Icons.chevron_right,
          onTap: () async {
            await sendEmail(context, to: supportEmail);
          },
        ),
        ExpandableChildItem(
          title: context.l10n.help,
          trailingIcon: Icons.chevron_right,
          onTap: () async {
            await PlatformUtil.openWebView(
              context,
              context.l10n.help,
              "https://ente.io/help",
            );
          },
        ),
        ExpandableChildItem(
          title: context.l10n.suggestFeatures,
          trailingIcon: Icons.chevron_right,
          onTap: () async {
            // ignore: unawaited_futures
            launchUrlString(
              githubDiscussionsUrl,
              mode: LaunchMode.externalApplication,
            );
          },
        ),
        ExpandableChildItem(
          title: context.l10n.reportABug,
          trailingIcon: Icons.chevron_right,
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
      ],
    );
  }
}
