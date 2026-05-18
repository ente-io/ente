import "dart:async";
import "dart:io";

import "package:ente_components/ente_components.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/duplicate_files.dart";
import "package:photos/models/freeable_space_info.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/deduplication_service.dart";
import "package:photos/services/files_service.dart";
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
    final colors = context.componentColors;

    return Scaffold(
      backgroundColor: colors.backgroundBase,
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
                  color: colors.iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).freeUpSpace,
                style: TextStyles.h1Bold.copyWith(color: colors.textBase),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFreeSpaceOption(
                        context,
                        title: AppLocalizations.of(context).freeUpDeviceSpace,
                        onTap: () async => _onFreeUpDeviceSpaceTapped(),
                      ),
                      _description(
                        AppLocalizations.of(context).freeUpDeviceSpaceDesc +
                            (Platform.isIOS
                                ? " ${AppLocalizations.of(context).freeUpDeviceSpaceDescICloud}"
                                : ""),
                      ),
                      _buildFreeSpaceOption(
                        context,
                        title: AppLocalizations.of(context).removeDuplicates,
                        onTap: () async => _onRemoveDuplicatesTapped(),
                      ),
                      _description(
                        AppLocalizations.of(context).removeDuplicatesDesc,
                      ),
                      if (flagService.enableVectorDb) ...[
                        _buildFreeSpaceOption(
                          context,
                          title: AppLocalizations.of(context).similarImages,
                          onTap: () async {
                            await routeToPage(
                              context,
                              const SimilarImagesPage(
                                debugScreen: kDebugMode,
                              ),
                            );
                          },
                        ),
                        _description(
                          AppLocalizations.of(context).useMLToFindSimilarImages,
                        ),
                      ],
                      _buildFreeSpaceOption(
                        context,
                        title: AppLocalizations.of(context).viewLargeFiles,
                        onTap: () async {
                          await routeToPage(
                            context,
                            LargeFilesPagePage(),
                          );
                        },
                      ),
                      _description(
                        AppLocalizations.of(context).viewLargeFilesDesc,
                      ),
                      _buildFreeSpaceOption(
                        context,
                        title: AppLocalizations.of(context).deleteSuggestions,
                        onTap: () async => _onDeleteSuggestionsTapped(),
                      ),
                      _description(
                        AppLocalizations.of(context).deleteSuggestionsDesc,
                      ),
                      _buildFreeSpaceOption(
                        context,
                        title: AppLocalizations.of(context).manageDeviceStorage,
                        onTap: () async {
                          await routeToPage(
                            context,
                            const AppStorageViewer(),
                          );
                        },
                      ),
                      _description(
                        AppLocalizations.of(context).manageDeviceStorageDesc,
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

  Widget _description(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        top: Spacing.sm,
        bottom: Spacing.lg,
      ),
      child: Text(
        text,
        style: TextStyles.mini.copyWith(
          color: context.componentColors.textLight,
        ),
      ),
    );
  }

  MenuComponent _buildFreeSpaceOption(
    BuildContext context, {
    required String title,
    required Future<void> Function() onTap,
  }) {
    final colors = context.componentColors;
    return MenuComponent(
      title: title,
      trailing: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight02,
        color: colors.textLight,
        size: 18,
        strokeWidth: 1.6,
      ),
      showOnlyLoadingState: true,
      onTap: onTap,
    );
  }

  Future<void> _onFreeUpDeviceSpaceTapped() async {
    FreeableSpaceInfo status;
    try {
      status = await FilesService.instance.getFreeableSpaceInfo();
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

  void _showSpaceFreedDialog(FreeableSpaceInfo status) {
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
      showBottomSheetComponent<void>(
        context: context,
        isDismissible: true,
        builder: (_) => BottomSheetComponent(
          title: AppLocalizations.of(context).success,
          message: AppLocalizations.of(context).youHaveSuccessfullyFreedUp(
            storageSaved: formatBytes(status.size),
          ),
          illustration: Icon(
            Icons.download_done_rounded,
            size: 64,
            color: context.componentColors.primary,
          ),
          actions: [
            ButtonComponent(
              label: AppLocalizations.of(context).ok,
              variant: ButtonComponentVariant.neutral,
              onTap: () async {
                if (Platform.isIOS) {
                  showToast(
                    context,
                    AppLocalizations.of(context).remindToEmptyDeviceTrash,
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
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
