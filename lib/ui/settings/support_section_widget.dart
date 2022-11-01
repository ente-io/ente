// @dart=2.9

import 'dart:io';

import 'package:ente_auth/core/constants.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/utils/email_util.dart';
import 'package:flutter/material.dart';

class SupportSectionWidget extends StatelessWidget {
  const SupportSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "Support",
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
          captionedTextWidget: const CaptionedTextWidget(
            title: "Email",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await sendEmail(context, to: supportEmail);
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Report a bug",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await sendLogs(context, "Report bug", bugsEmail);
          },
          onDoubleTap: () async {
            final zipFilePath = await getZippedLogsFile(context);
            await shareLogs(context, bugsEmail, zipFilePath);
          },
        ),
        sectionOptionSpacing,
      ],
    );
  }
}
