import "dart:async";
import 'dart:io';

import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/backup_status.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/services/deduplication_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import 'package:photos/ui/settings/backup/backup_folder_selection_page.dart';
import 'package:photos/ui/settings/backup/backup_settings_screen.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/tools/deduplicate_page.dart';
import "package:photos/ui/tools/free_space_page.dart";
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/dialog_util.dart';
import "package:photos/utils/local_settings.dart";
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';

class BackupSectionWidget extends StatefulWidget {
  const BackupSectionWidget({Key? key}) : super(key: key);

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
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          await routeToPage(
            context,
            BackupFolderSelectionPage(
              buttonText: S.of(context).backup,
            ),
          );
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: S.of(context).backupSettings,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
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
            title: S.of(context).freeUpDeviceSpace,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          showOnlyLoadingState: true,
          onTap: () async {
            BackupStatus status;
            try {
              status = await SyncService.instance.getBackupStatus();
            } catch (e) {
              await showGenericErrorDialog(context: context, error: e);
              return;
            }

            if (status.localIDs.isEmpty) {
              // ignore: unawaited_futures
              showErrorDialog(
                context,
                S.of(context).allClear,
                S.of(context).noDeviceThatCanBeDeleted,
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
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).removeDuplicates,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          showOnlyLoadingState: true,
          onTap: () async {
            List<DuplicateFiles> duplicates;
            try {
              duplicates =
                  await DeduplicationService.instance.getDuplicateFiles();
            } catch (e) {
              await showGenericErrorDialog(context: context, error: e);
              return;
            }

            if (duplicates.isEmpty) {
              unawaited(
                showErrorDialog(
                  context,
                  S.of(context).noDuplicates,
                  S.of(context).youveNoDuplicateFilesThatCanBeCleared,
                ),
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
    if (LocalSettings.instance.shouldPromptToRateUs()) {
      LocalSettings.instance.setRateUsShownCount(
        LocalSettings.instance.getRateUsShownCount() + 1,
      );
      showChoiceDialog(
        context,
        title: S.of(context).success,
        body:
            S.of(context).youHaveSuccessfullyFreedUp(formatBytes(status.size)),
        firstButtonLabel: S.of(context).rateUs,
        firstButtonOnTap: () async {
          await UpdateService.instance.launchReviewUrl();
        },
        firstButtonType: ButtonType.primary,
        secondButtonLabel: S.of(context).ok,
        secondButtonOnTap: () async {
          if (Platform.isIOS) {
            showToast(context, S.of(context).remindToEmptyDeviceTrash);
          }
        },
      );
    } else {
      showDialogWidget(
        context: context,
        title: S.of(context).success,
        body:
            S.of(context).youHaveSuccessfullyFreedUp(formatBytes(status.size)),
        icon: Icons.download_done_rounded,
        isDismissible: true,
        buttons: [
          ButtonWidget(
            buttonType: ButtonType.neutral,
            labelText: S.of(context).ok,
            isInAlert: true,
            onTap: () async {
              if (Platform.isIOS) {
                showToast(context, S.of(context).remindToEmptyDeviceTrash);
              }
            },
          ),
        ],
      );
    }
  }

  void _showDuplicateFilesDeletedDialog(DeduplicationResult result) {
    showChoiceDialog(
      context,
      title: S.of(context).sparkleSuccess,
      body: S.of(context).duplicateFileCountWithStorageSaved(
            result.count,
            formatBytes(result.size),
          ),
      firstButtonLabel: S.of(context).rateUs,
      firstButtonOnTap: () async {
        await UpdateService.instance.launchReviewUrl();
      },
      firstButtonType: ButtonType.primary,
      secondButtonLabel: S.of(context).ok,
      secondButtonOnTap: () async {
        showShortToast(
          context,
          S.of(context).remindToEmptyEnteTrash,
        );
      },
    );
  }
}
