import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/ui/settings/data/export_widget.dart';
import 'package:ente_auth/ui/settings/data/import_page.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:flutter/material.dart';

class DataSectionWidget extends StatelessWidget {
  // final _logger = Logger("AccountSectionWidget");

  DataSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.data,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.key_outlined,
    );
  }

  Column _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;
    List<Widget> children = [];
    children.addAll([
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: l10n.importCodes,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          await routeToPage(context, const ImportCodePage());
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: l10n.exportCodes,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          await handleExportClick(context);
        },
      ),
      sectionOptionSpacing,
    ]);
    return Column(
      children: children,
    );
  }
}
