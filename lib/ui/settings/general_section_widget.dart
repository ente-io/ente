import 'package:ente_auth/core/logging/super_logging.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/toggle_switch_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:flutter/material.dart';

class GeneralSectionWidget extends StatefulWidget {
  const GeneralSectionWidget({Key? key}) : super(key: key);

  @override
  State<GeneralSectionWidget> createState() => _GeneralSectionWidgetState();
}

class _GeneralSectionWidgetState extends State<GeneralSectionWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.general,
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
            title: l10n.showLargeIcons,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => PreferenceService.instance.shouldShowLargeIcons(),
            onChanged: () async {
              await PreferenceService.instance.setShowLargeIcons(
                !PreferenceService.instance.shouldShowLargeIcons(),
              );
              setState(() {});
            },
          ),
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.crashAndErrorReporting,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => SuperLogging.shouldReportErrors(),
            onChanged: () async {
              await SuperLogging.setShouldReportErrors(
                !SuperLogging.shouldReportErrors(),
              );
              setState(() {});
            },
          ),
        ),
        sectionOptionSpacing,
      ],
    );
  }
}
