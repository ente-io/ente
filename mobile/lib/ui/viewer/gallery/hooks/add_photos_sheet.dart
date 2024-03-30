import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/files_db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import "package:photos/models/selected_files.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/filter/db_filters.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/components/bottom_of_title_bar_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
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
                            title: S.of(context).addMore,
                          ),
                          caption: S.of(context).selectItemsToAdd,
                          showCloseButton: true,
                        ),
                        Expanded(
                          child: Gallery(
                            inSelectionMode: true,
                            asyncLoader: (
                              creationStartTime,
                              creationEndTime, {
                              limit,
                              asc,
                            }) {
                              return FilesDB.instance
                                  .getAllPendingOrUploadedFiles(
                                creationStartTime,
                                creationEndTime,
                                Configuration.instance.getUserID()!,
                                limit: limit,
                                asc: asc,
                                filterOptions: DBFilterOptions(
                                  hideIgnoredForUpload: true,
                                  dedupeUploadID: true,
                                  ignoredCollectionIDs: hiddenCollectionIDs,
                                ),
                                applyOwnerCheck: true,
                              );
                            },
                            tagPrefix: "pick_add_photos_gallery",
                            selectedFiles: selectedFiles,
                            showSelectAllByDefault: true,
                            sortAsyncFn: () => false,
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
                                  labelText: S.of(context).addSelected,
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
                            labelText: S.of(context).addFromDevice,
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
      final List<AssetEntity>? result = await AssetPicker.pickAssets(context);
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
        final PermissionState ps = await PhotoManager.requestPermissionExtend(
          requestOption: const PermissionRequestOption(
            androidPermission: AndroidPermission(
              type: RequestType.common,
              mediaLocation: true,
            ),
          ),
        );
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
}
