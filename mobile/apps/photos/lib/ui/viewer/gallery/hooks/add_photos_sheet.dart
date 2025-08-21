import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import "package:photos/models/selected_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/filter/db_filters.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/bottom_of_title_bar_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/utils/dialog_util.dart";
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

Future<dynamic> showAddPhotosSheet(
  BuildContext context,
  Collection collection,
) async {
  return await showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return AddPhotosPhotoWidget(collection);
    },
    shape: const RoundedRectangleBorder(
      side: BorderSide(width: 0),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(5),
      ),
    ),
    topControl: const SizedBox.shrink(),
    backgroundColor: getEnteColorScheme(context).backgroundElevated,
    barrierColor: backdropFaintDark,
    enableDrag: false,
  );
}

class AddPhotosPhotoWidget extends StatelessWidget {
  final Collection collection;

  const AddPhotosPhotoWidget(
    this.collection, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isFileSelected = ValueNotifier(false);
    final selectedFiles = SelectedFiles();
    selectedFiles.addListener(() {
      isFileSelected.value = selectedFiles.files.isNotEmpty;
    });
    final Set<int> hiddenCollectionIDs =
        CollectionsService.instance.getHiddenCollectionIds();
    // Hide the current collection files from suggestions
    hiddenCollectionIDs.add(collection.id);

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: min(428, MediaQuery.of(context).size.width),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        BottomOfTitleBarWidget(
                          title: TitleBarTitleWidget(
                            title: AppLocalizations.of(context).addMore,
                          ),
                          caption:
                              AppLocalizations.of(context).selectItemsToAdd,
                          showCloseButton: true,
                        ),
                        Expanded(
                          child: DelayedGallery(
                            hiddenCollectionIDs: hiddenCollectionIDs,
                            selectedFiles: selectedFiles,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Container(
                      //inner stroke of 1pt + 15 pts of top padding = 16 pts
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: getEnteColorScheme(context).strokeFaint,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          ValueListenableBuilder(
                            valueListenable: isFileSelected,
                            builder: (context, bool value, _) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeInOutExpo,
                                switchOutCurve: Curves.easeInOutExpo,
                                child: ButtonWidget(
                                  key: ValueKey(value),
                                  // isDisabled: !value,
                                  buttonType: ButtonType.primary,
                                  labelText:
                                      AppLocalizations.of(context).addSelected,
                                  onTap: () async {
                                    final selectedFile = selectedFiles.files;
                                    final ca = CollectionActions(
                                      CollectionsService.instance,
                                    );
                                    await ca.addToCollection(
                                      context,
                                      collection.id,
                                      false,
                                      selectedFiles: selectedFile.toList(),
                                    );
                                    Navigator.pop(context, selectedFile);
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          ButtonWidget(
                            buttonType: ButtonType.secondary,
                            buttonAction: ButtonAction.second,
                            labelText:
                                AppLocalizations.of(context).addFromDevice,
                            onTap: () async {
                              await _onPickFromDeviceClicked(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPickFromDeviceClicked(BuildContext context) async {
    try {
      final assetPickerTextDelegate = await _getAssetPickerTextDelegate();
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          keepScrollOffset: true,
          maxAssets: maxPickAssetLimit,
          textDelegate: assetPickerTextDelegate,
          gridCount: 6,
          pageSize: 120,
        ),
      );
      if (result != null && result.isNotEmpty) {
        final ca = CollectionActions(
          CollectionsService.instance,
        );
        await ca.addToCollection(
          context,
          collection.id,
          false,
          picketAssets: result,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (e is StateError) {
        final PermissionState ps =
            await permissionService.requestPhotoMangerPermissions();
        if (ps != PermissionState.authorized && ps != PermissionState.limited) {
          await showChoiceDialog(
            context,
            title: context.l10n.grantPermission,
            body: context.l10n.pleaseGrantPermissions,
            firstButtonLabel: context.l10n.ok,
            secondButtonLabel: context.l10n.cancel,
            firstButtonOnTap: () async {
              await PhotoManager.openSetting();
            },
          );
        } else {
          await showErrorDialog(
            context,
            context.l10n.oops,
            context.l10n.somethingWentWrong + (kDebugMode ? "\n$e" : ""),
          );
        }
      }
    }
  }

  // _getAssetPickerTextDelegate returns the text delegate for the asset picker
  // This custom method is required to enforce English as the default fallback
  // instead of Chinese.
  Future<AssetPickerTextDelegate> _getAssetPickerTextDelegate() async {
    final Locale locale = (await getLocale())!;
    switch (locale.languageCode.toLowerCase()) {
      case "en":
        return const EnglishAssetPickerTextDelegate();
      case "he":
        return const HebrewAssetPickerTextDelegate();
      case "de":
        return const GermanAssetPickerTextDelegate();
      case "ru":
        return const RussianAssetPickerTextDelegate();
      case "ja":
        return const JapaneseAssetPickerTextDelegate();
      case "ar":
        return const ArabicAssetPickerTextDelegate();
      case "fr":
        return const FrenchAssetPickerTextDelegate();
      case "vi":
        return const VietnameseAssetPickerTextDelegate();
      case "tr":
        return const TurkishAssetPickerTextDelegate();
      case "ko":
        return const KoreanAssetPickerTextDelegate();
      case "zh":
        return const AssetPickerTextDelegate();
      default:
        return const EnglishAssetPickerTextDelegate();
    }
  }
}

class DelayedGallery extends StatefulWidget {
  const DelayedGallery({
    super.key,
    required this.hiddenCollectionIDs,
    required this.selectedFiles,
  });

  final Set<int> hiddenCollectionIDs;
  final SelectedFiles selectedFiles;

  @override
  State<DelayedGallery> createState() => _DelayedGalleryState();
}

class _DelayedGalleryState extends State<DelayedGallery> {
  bool _showGallery = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showGallery = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showGallery) {
      return GalleryFilesState(
        child: Gallery(
          inSelectionMode: true,
          asyncLoader: (
            creationStartTime,
            creationEndTime, {
            limit,
            asc,
          }) {
            return FilesDB.instance.getAllPendingOrUploadedFiles(
              creationStartTime,
              creationEndTime,
              Configuration.instance.getUserID()!,
              limit: limit,
              asc: asc,
              filterOptions: DBFilterOptions(
                hideIgnoredForUpload: true,
                dedupeUploadID: true,
                ignoredCollectionIDs: widget.hiddenCollectionIDs,
              ),
              applyOwnerCheck: true,
            );
          },
          tagPrefix: "pick_add_photos_gallery",
          selectedFiles: widget.selectedFiles,
          showSelectAll: true,
          sortAsyncFn: () => false,
          disablePinnedGroupHeader: true,
          disableVerticalPaddingForScrollbar: true,
        ).animate().fadeIn(
              duration: const Duration(milliseconds: 175),
              curve: Curves.easeOutCirc,
            ),
      );
    } else {
      return const EnteLoadingWidget();
    }
  }
}
