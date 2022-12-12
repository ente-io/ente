// @dart=2.9

import 'package:ente_auth/core/constants.dart';
import 'package:ente_auth/core/logging/super_logging.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/toggle_switch_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/utils/email_util.dart';
import 'package:flutter/material.dart';

class SupportSectionWidget extends StatefulWidget {
  const SupportSectionWidget({Key key}) : super(key: key);

  @override
  State<SupportSectionWidget> createState() => _SupportSectionWidgetState();
}

class _SupportSectionWidgetState extends State<SupportSectionWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.support,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.help_outline_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.email,
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
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.reportABug,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await sendLogs(context, l10n.reportBug, "auth@ente.io");
          },
          onDoubleTap: () async {
            final zipFilePath = await getZippedLogsFile(context);
            await shareLogs(context, "auth@ente.io", zipFilePath);
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.crashAndErrorReporting,
          ),
          trailingSwitch: ToggleSwitchWidget(
            value: SuperLogging.shouldReportErrors(),
            onChanged: (value) async {
              await SuperLogging.setShouldReportErrors(value);
              setState(() {});
            },
          ),
        ),
        sectionOptionSpacing,
      ],
    );
  }
}
