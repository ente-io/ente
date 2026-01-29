import "dart:async";
import "dart:io";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart" show kDebugMode;
import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/backup_status.dart";
import "package:photos/models/duplicate_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/deduplication_service.dart";
import "package:photos/services/files_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/tools/debug/app_storage_viewer.dart";
import "package:photos/ui/tools/deduplicate_page.dart";
import "package:photos/ui/tools/free_space_page.dart";
import "package:photos/ui/tools/similar_images_page.dart";
import "package:photos/ui/viewer/gallery/delete_suggestions_page.dart";
import "package:photos/ui/viewer/gallery/large_files_page.dart";
import "package:photos/utils/dialog_util.dart";

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
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).freeUpSpace,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).freeUpDeviceSpace,
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        showOnlyLoadingState: true,
                        onTap: () async => _onFreeUpDeviceSpaceTapped(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 16,
                        ),
                        child: Text(
                          AppLocalizations.of(context).freeUpDeviceSpaceDesc,
                          style: textTheme.mini
                              .copyWith(color: colorScheme.textMuted),
                        ),
                      ),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).removeDuplicates,
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        showOnlyLoadingState: true,
                        onTap: () async => _onRemoveDuplicatesTapped(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 16,
                        ),
                        child: Text(
                          AppLocalizations.of(context).removeDuplicatesDesc,
                          style: textTheme.mini
                              .copyWith(color: colorScheme.textMuted),
                        ),
                      ),
                      if (flagService.enableVectorDb) ...[
                        MenuItemWidgetNew(
                          title: AppLocalizations.of(context).similarImages,
                          trailingIcon: Icons.chevron_right_outlined,
                          trailingIconIsMuted: true,
                          showOnlyLoadingState: true,
                          onTap: () async {
                            await routeToPage(
                              context,
                              const SimilarImagesPage(
                                debugScreen: kDebugMode,
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 16,
                          ),
                          child: Text(
                            AppLocalizations.of(context)
                                .useMLToFindSimilarImages,
                            style: textTheme.mini
                                .copyWith(color: colorScheme.textMuted),
                          ),
                        ),
                      ],
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).viewLargeFiles,
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        showOnlyLoadingState: true,
                        onTap: () async {
                          await routeToPage(
                            context,
                            LargeFilesPagePage(),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 16,
                        ),
                        child: Text(
                          AppLocalizations.of(context).viewLargeFilesDesc,
                          style: textTheme.mini
                              .copyWith(color: colorScheme.textMuted),
                        ),
                      ),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).deleteSuggestions,
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        showOnlyLoadingState: true,
                        onTap: () async => _onDeleteSuggestionsTapped(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 16,
                        ),
                        child: Text(
                          AppLocalizations.of(context).deleteSuggestionsDesc,
                          style: textTheme.mini
                              .copyWith(color: colorScheme.textMuted),
                        ),
                      ),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).manageDeviceStorage,
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await routeToPage(
                            context,
                            const AppStorageViewer(),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 16,
                        ),
                        child: Text(
                          AppLocalizations.of(context).manageDeviceStorageDesc,
                          style: textTheme.mini
                              .copyWith(color: colorScheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onFreeUpDeviceSpaceTapped() async {
    BackupStatus status;
    try {
      status = await FilesService.instance.getBackupStatus();
    } catch (e) {
      await showGenericErrorDialog(
        context: context,
        error: e,
      );
      return;
    }

    if (status.localIDs.isEmpty) {
      unawaited(
        showErrorDialog(
          context,
          AppLocalizations.of(context).allClear,
          AppLocalizations.of(context).noDeviceThatCanBeDeleted,
        ),
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
  }

  Future<void> _onRemoveDuplicatesTapped() async {
    List<DuplicateFiles> duplicates;
    try {
      duplicates = await DeduplicationService.instance.getDuplicateFiles();
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
          AppLocalizations.of(context).noDuplicates,
          AppLocalizations.of(context).youveNoDuplicateFilesThatCanBeCleared,
        ),
      );
    } else {
      final DeduplicationResult? result = await routeToPage(
        context,
        DeduplicatePage(duplicates),
      );
      if (result != null) {
        _showDuplicateFilesDeletedDialog(result);
      }
    }
  }

  Future<void> _onDeleteSuggestionsTapped() async {
    List<int> suggestionFileIDs;
    try {
      suggestionFileIDs =
          await CollectionsService.instance.fetchDeleteSuggestionFileIDs();
    } catch (e) {
      await showGenericErrorDialog(
        context: context,
        error: e,
      );
      return;
    }

    if (suggestionFileIDs.isEmpty) {
      unawaited(
        showErrorDialog(
          context,
          AppLocalizations.of(context).noDeleteSuggestion,
          AppLocalizations.of(context).youHaveNoFileSuggestedForDeletion,
        ),
      );
    } else {
      await routeToPage(
        context,
        DeleteSuggestionsPage(),
      );
    }
  }

  void _showSpaceFreedDialog(BackupStatus status) {
    if (localSettings.shouldPromptToRateUs()) {
      localSettings.setRateUsShownCount(
        localSettings.getRateUsShownCount() + 1,
      );
      showChoiceDialog(
        context,
        title: AppLocalizations.of(context).success,
        body: AppLocalizations.of(context)
            .youHaveSuccessfullyFreedUp(storageSaved: formatBytes(status.size)),
        firstButtonLabel: AppLocalizations.of(context).rateUs,
        firstButtonOnTap: () async {
          await updateService.launchReviewUrl();
        },
        firstButtonType: ButtonType.primary,
        secondButtonLabel: AppLocalizations.of(context).ok,
        secondButtonOnTap: () async {
          if (Platform.isIOS) {
            showToast(
              context,
              AppLocalizations.of(context).remindToEmptyDeviceTrash,
            );
          }
        },
      );
    } else {
      showDialogWidget(
        context: context,
        title: AppLocalizations.of(context).success,
        body: AppLocalizations.of(context)
            .youHaveSuccessfullyFreedUp(storageSaved: formatBytes(status.size)),
        icon: Icons.download_done_rounded,
        isDismissible: true,
        buttons: [
          ButtonWidget(
            buttonType: ButtonType.neutral,
            labelText: AppLocalizations.of(context).ok,
            isInAlert: true,
            onTap: () async {
              if (Platform.isIOS) {
                showToast(
                  context,
                  AppLocalizations.of(context).remindToEmptyDeviceTrash,
                );
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
      title: AppLocalizations.of(context).sparkleSuccess,
      body: AppLocalizations.of(context).duplicateFileCountWithStorageSaved(
        count: result.count,
        storageSaved: formatBytes(result.size),
      ),
      firstButtonLabel: AppLocalizations.of(context).rateUs,
      firstButtonOnTap: () async {
        await updateService.launchReviewUrl();
      },
      firstButtonType: ButtonType.primary,
      secondButtonLabel: AppLocalizations.of(context).ok,
      secondButtonOnTap: () async {
        showShortToast(
          context,
          AppLocalizations.of(context).remindToEmptyEnteTrash,
        );
      },
    );
  }
}
