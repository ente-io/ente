import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/captioned_text_widget.dart";
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/backup/backup_folder_selection_page.dart';
import 'package:photos/ui/settings/backup/backup_settings_screen.dart';
import "package:photos/ui/settings/backup/backup_status_screen.dart";
import "package:photos/ui/settings/backup/free_space_options.dart";
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/utils/navigation_util.dart';

class BackupSectionWidget extends StatefulWidget {
  const BackupSectionWidget({super.key});

  @override
  BackupSectionWidgetState createState() => BackupSectionWidgetState();
}

class BackupSectionWidgetState extends State<BackupSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: S.of(context).backup,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.backup_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final List<Widget> sectionOptions = [
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: S.of(context).backedUpFolders,
        ),
        pressedColor: EnteTheme.getColorScheme(theme).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          await routeToPage(
            context,
            const BackupFolderSelectionPage(
              isFirstBackup: false,
            ),
          );
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: S.of(context).backupStatus,
        ),
        pressedColor: EnteTheme.getColorScheme(theme).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          await routeToPage(
            context,
            const BackupStatusScreen(),
          );
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: S.of(context).backupSettings,
        ),
        pressedColor: EnteTheme.getColorScheme(theme).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          await routeToPage(
            context,
            const BackupSettingsScreen(),
          );
        },
      ),
      sectionOptionSpacing,
    ];

    sectionOptions.addAll(
      [
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).freeUpSpace,
          ),
          pressedColor: EnteTheme.getColorScheme(theme).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          showOnlyLoadingState: true,
          onTap: () async {
            await routeToPage(
              context,
              const FreeUpSpaceOptionsScreen(),
            );
          },
        ),
        sectionOptionSpacing,
      ],
    );
    return Column(
      children: sectionOptions,
    );
  }
}
