import "dart:async";
import "dart:io";

import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/backup_status.dart";
import "package:photos/models/duplicate_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/deduplication_service.dart";
import "package:photos/services/sync_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import "package:photos/ui/components/dialog_widget.dart";
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import "package:photos/ui/components/menu_section_description_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/tools/debug/app_storage_viewer.dart";
import "package:photos/ui/tools/deduplicate_page.dart";
import "package:photos/ui/tools/free_space_page.dart";
import "package:photos/ui/viewer/gallery/large_files_page.dart";
import "package:photos/utils/data_util.dart";
import "package:photos/utils/dialog_util.dart";
import 'package:photos/utils/navigation_util.dart';
import "package:photos/utils/toast_util.dart";

class FreeUpSpaceOptionsScreen extends StatefulWidget {
  const FreeUpSpaceOptionsScreen({super.key});

  @override
  State<FreeUpSpaceOptionsScreen> createState() =>
      _FreeUpSpaceOptionsScreenState();
}

class _FreeUpSpaceOptionsScreenState extends State<FreeUpSpaceOptionsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).freeUpSpace,
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (delegateBuildContext, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Column(
                              children: [
                                MenuItemWidget(
                                  captionedTextWidget: CaptionedTextWidget(
                                    title: S.of(context).freeUpDeviceSpace,
                                  ),
                                  menuItemColor: colorScheme.fillFaint,
                                  trailingWidget: Icon(
                                    Icons.chevron_right_outlined,
                                    color: colorScheme.strokeBase,
                                  ),
                                  singleBorderRadius: 8,
                                  alignCaptionedTextToLeft: true,
                                  showOnlyLoadingState: true,
                                  onTap: () async {
                                    BackupStatus status;
                                    try {
                                      status = await SyncService.instance
                                          .getBackupStatus();
                                    } catch (e) {
                                      await showGenericErrorDialog(
                                        context: context,
                                        error: e,
                                      );
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
                                      final bool? result = await routeToPage(
                                        context,
                                        FreeSpacePage(status),
                                      );
                                      if (result == true) {
                                        _showSpaceFreedDialog(status);
                                      }
                                    }
                                  },
                                ),
                                MenuSectionDescriptionWidget(
                                  content: S.of(context).freeUpDeviceSpaceDesc,
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                MenuItemWidget(
                                  captionedTextWidget: CaptionedTextWidget(
                                    title: S.of(context).removeDuplicates,
                                  ),
                                  menuItemColor: colorScheme.fillFaint,
                                  trailingWidget: Icon(
                                    Icons.chevron_right_outlined,
                                    color: colorScheme.strokeBase,
                                  ),
                                  singleBorderRadius: 8,
                                  alignCaptionedTextToLeft: true,
                                  trailingIconIsMuted: true,
                                  showOnlyLoadingState: true,
                                  onTap: () async {
                                    List<DuplicateFiles> duplicates;
                                    try {
                                      duplicates = await DeduplicationService
                                          .instance
                                          .getDuplicateFiles();
                                    } catch (e) {
                                      await showGenericErrorDialog(
                                        context: context,
                                        error: e,
                                      );
                                      return;
                                    }

                                    if (duplicates.isEmpty) {
                                      unawaited(
                                        showErrorDialog(
                                          context,
                                          S.of(context).noDuplicates,
                                          S
                                              .of(context)
                                              .youveNoDuplicateFilesThatCanBeCleared,
                                        ),
                                      );
                                    } else {
                                      final DeduplicationResult? result =
                                          await routeToPage(
                                        context,
                                        DeduplicatePage(duplicates),
                                      );
                                      if (result != null) {
                                        _showDuplicateFilesDeletedDialog(
                                          result,
                                        );
                                      }
                                    }
                                  },
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: MenuSectionDescriptionWidget(
                                    content: S.of(context).removeDuplicatesDesc,
                                  ),
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                MenuItemWidget(
                                  captionedTextWidget: CaptionedTextWidget(
                                    title: S.of(context).viewLargeFiles,
                                  ),
                                  menuItemColor: colorScheme.fillFaint,
                                  trailingWidget: Icon(
                                    Icons.chevron_right_outlined,
                                    color: colorScheme.strokeBase,
                                  ),
                                  singleBorderRadius: 8,
                                  alignCaptionedTextToLeft: true,
                                  trailingIconIsMuted: true,
                                  showOnlyLoadingState: true,
                                  onTap: () async {
                                    await routeToPage(
                                      context,
                                      LargeFilesPagePage(),
                                    );
                                  },
                                ),
                                MenuSectionDescriptionWidget(
                                  content: S.of(context).viewLargeFilesDesc,
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                MenuItemWidget(
                                  captionedTextWidget: CaptionedTextWidget(
                                    title: S.of(context).manageDeviceStorage,
                                  ),
                                  menuItemColor: colorScheme.fillFaint,
                                  trailingWidget: Icon(
                                    Icons.chevron_right_outlined,
                                    color: colorScheme.strokeBase,
                                  ),
                                  singleBorderRadius: 8,
                                  alignCaptionedTextToLeft: true,
                                  onTap: () async {
                                    // ignore: unawaited_futures
                                    routeToPage(
                                      context,
                                      const AppStorageViewer(),
                                    );
                                  },
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: MenuSectionDescriptionWidget(
                                    content:
                                        S.of(context).manageDeviceStorageDesc,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showSpaceFreedDialog(BackupStatus status) {
    if (localSettings.shouldPromptToRateUs()) {
      localSettings.setRateUsShownCount(
        localSettings.getRateUsShownCount() + 1,
      );
      showChoiceDialog(
        context,
        title: S.of(context).success,
        body:
            S.of(context).youHaveSuccessfullyFreedUp(formatBytes(status.size)),
        firstButtonLabel: S.of(context).rateUs,
        firstButtonOnTap: () async {
          await updateService.launchReviewUrl();
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
        await updateService.launchReviewUrl();
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
