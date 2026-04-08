import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/bottom_of_title_bar_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";

Future<EnteFile?> showContactPhotoPickerSheet(
  BuildContext context, {
  List<EnteFile>? initialFiles,
}) {
  return showBarModalBottomSheet<EnteFile>(
    context: context,
    builder: (context) => _ContactPhotoPickerSheet(initialFiles: initialFiles),
    shape: const RoundedRectangleBorder(
      side: BorderSide(width: 0),
      borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
    ),
    topControl: const SizedBox.shrink(),
    backgroundColor: getEnteColorScheme(context).backgroundElevated,
    barrierColor: backdropFaintDark,
    enableDrag: true,
  );
}

class _ContactPhotoPickerSheet extends StatelessWidget {
  final List<EnteFile>? initialFiles;

  const _ContactPhotoPickerSheet({this.initialFiles});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFileSelected = ValueNotifier(false);
    final selectedFiles = SelectedFiles();
    selectedFiles.addListener(() {
      isFileSelected.value = selectedFiles.files.isNotEmpty;
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Column(
                children: [
                  BottomOfTitleBarWidget(
                    title: TitleBarTitleWidget(title: l10n.setAContactPhoto),
                    showCloseButton: true,
                  ),
                  Expanded(
                    child: GalleryFilesState(
                      child: Gallery(
                        asyncLoader: (
                          creationStartTime,
                          creationEndTime, {
                          limit,
                          asc,
                        }) async {
                          final files =
                              initialFiles == null || initialFiles!.isEmpty
                                  ? await SearchService.instance
                                      .getAllFilesForGenericGallery()
                                  : initialFiles!;
                          return FileLoadResult(files, false);
                        },
                        tagPrefix: "pick_contact_photo_gallery",
                        selectedFiles: selectedFiles,
                        limitSelectionToOne: true,
                        showSelectAll: false,
                        disablePinnedGroupHeader: true,
                        disableVerticalPaddingForScrollbar: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: getEnteColorScheme(context).strokeFaint,
                    ),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 428),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isFileSelected,
                        builder: (context, value, _) {
                          return ButtonWidget(
                            key: ValueKey(value),
                            isDisabled: !value,
                            buttonType: ButtonType.neutral,
                            labelText:
                                AppLocalizations.of(context).useSelectedPhoto,
                            onTap: () async {
                              Navigator.pop(context, selectedFiles.files.first);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
