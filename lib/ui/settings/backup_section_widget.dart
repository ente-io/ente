

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photos/models/backup_status.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/services/deduplication_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/backup_folder_selection_page.dart';
import 'package:photos/ui/backup_settings_screen.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/tools/deduplicate_page.dart';
import 'package:photos/ui/tools/free_space_page.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BackupSectionWidget extends StatefulWidget {
  const BackupSectionWidget({Key? key}) : super(key: key);

  @override
  BackupSectionWidgetState createState() => BackupSectionWidgetState();
}

class BackupSectionWidgetState extends State<BackupSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "Backup",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.backup_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final List<Widget> sectionOptions = [
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          title: "Backed up folders",
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () {
          routeToPage(
            context,
            const BackupFolderSelectionPage(
              buttonText: "Backup",
            ),
          );
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          title: "Backup settings",
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () {
          routeToPage(
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
          captionedTextWidget: const CaptionedTextWidget(
            title: "Free up device space",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            final dialog = createProgressDialog(context, "Calculating...");
            await dialog.show();
            BackupStatus status;
            try {
              status = await SyncService.instance.getBackupStatus();
            } catch (e) {
              await dialog.hide();
              showGenericErrorDialog(context: context);
              return;
            }

            await dialog.hide();
            if (status.localIDs.isEmpty) {
              showErrorDialog(
                context,
                "✨ All clear",
                "You've no files on this device that can be deleted",
              );
            } else {
              final bool? result =
                  await routeToPage(context, FreeSpacePage(status));
              if (result == true) {
                _showSpaceFreedDialog(status);
              }
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Remove duplicates",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            final dialog = createProgressDialog(context, "Calculating...");
            await dialog.show();
            List<DuplicateFiles> duplicates;
            try {
              duplicates =
                  await DeduplicationService.instance.getDuplicateFiles();
            } catch (e) {
              await dialog.hide();
              showGenericErrorDialog(context: context);
              return;
            }

            await dialog.hide();
            if (duplicates.isEmpty) {
              showErrorDialog(
                context,
                "✨ No duplicates",
                "You've no duplicate files that can be cleared",
              );
            } else {
              final DeduplicationResult? result =
                  await routeToPage(context, DeduplicatePage(duplicates));
              if (result != null) {
                _showDuplicateFilesDeletedDialog(result);
              }
            }
          },
        ),
        sectionOptionSpacing,
      ],
    );
    return Column(
      children: sectionOptions,
    );
  }

  void _showSpaceFreedDialog(BackupStatus status) {
    final DialogWidget dialog = choiceDialog(
      title: "Success",
      body: "You have successfully freed up " + formatBytes(status.size) + "!",
      firstButtonLabel: "Rate us",
      firstButtonOnTap: () async {
        final url = UpdateService.instance.getRateDetails().item2;
        launchUrlString(url);
      },
      firstButtonType: ButtonType.primary,
      secondButtonLabel: "OK",
      secondButtonOnTap: () async {
        if (Platform.isIOS) {
          showToast(
            context,
            "Also empty \"Recently Deleted\" from \"Settings\" -> \"Storage\" to claim the freed space",
          );
        }
      },
    );

    showConfettiDialog(
      context: context,
      dialogBuilder: (BuildContext context) {
        return dialog;
      },
      barrierColor: Colors.black87,
      confettiAlignment: Alignment.topCenter,
      useRootNavigator: true,
    );
  }

  void _showDuplicateFilesDeletedDialog(DeduplicationResult result) {
    final String countText = result.count.toString() +
        " duplicate file" +
        (result.count == 1 ? "" : "s");
    final DialogWidget dialog = choiceDialog(
      title: "✨ Success",
      body: "You have cleaned up " +
          countText +
          ", saving " +
          formatBytes(result.size) +
          "!",
      firstButtonLabel: "Rate us",
      firstButtonOnTap: () async {
        // TODO: Replace with https://pub.dev/packages/in_app_review
        final url = UpdateService.instance.getRateDetails().item2;
        launchUrlString(url);
      },
      firstButtonType: ButtonType.primary,
      secondButtonLabel: "OK",
      secondButtonOnTap: () async {
        showShortToast(
          context,
          "Also empty your \"Trash\" to claim the freed up space",
        );
      },
    );

    showConfettiDialog(
      context: context,
      dialogBuilder: (BuildContext context) {
        return dialog;
      },
      barrierColor: Colors.black87,
      confettiAlignment: Alignment.topCenter,
      useRootNavigator: true,
    );
  }
}
