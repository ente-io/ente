import "dart:math";

import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/bottom_of_title_bar_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";

Future<dynamic> showPersonAvatarPhotoSheet(
  BuildContext context,
  PersonEntity person,
) async {
  return await showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return PickPersonCoverPhotoWidget(person);
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

class PickPersonCoverPhotoWidget extends StatelessWidget {
  final PersonEntity personEntity;

  const PickPersonCoverPhotoWidget(
    this.personEntity, {
    super.key,
  });

  Future<FileLoadResult> loadPersonFiles() async {
    final result = await SearchService.instance
        .getClusterFilesForPersonID(personEntity.remoteID);

    final List<EnteFile> resultFiles = [];
    for (final e in result.entries) {
      resultFiles.addAll(e.value);
    }
    final List<EnteFile> sortedFiles = List<EnteFile>.from(resultFiles);
    sortedFiles.sort((a, b) => b.creationTime!.compareTo(a.creationTime!));

    return FileLoadResult(sortedFiles, false);
  }

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isFileSelected = ValueNotifier(false);
    final selectedFiles = SelectedFiles();
    selectedFiles.addListener(() {
      isFileSelected.value = selectedFiles.files.isNotEmpty;
    });

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
                            title: S.of(context).selectCoverPhoto,
                          ),
                          caption: personEntity.data.name,
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
                                final FileLoadResult result =
                                    await loadPersonFiles();

                                return result;
                              },
                              // reloadEvent: Bus.instance
                              //     .on<CollectionUpdatedEvent>()
                              //     .where(
                              //       (event) =>
                              //           event.collectionID == collection.id,
                              //     ),
                              tagPrefix: "pick_center_point_gallery",
                              selectedFiles: selectedFiles,
                              limitSelectionToOne: true,
                              showSelectAllByDefault: false,
                            ),
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
                                  isDisabled: !value,
                                  buttonType: ButtonType.neutral,
                                  labelText: S.of(context).useSelectedPhoto,
                                  onTap: () async {
                                    final selectedFile =
                                        selectedFiles.files.first;
                                    final result = await PersonService.instance
                                        .updateAvatar(
                                      personEntity,
                                      selectedFile,
                                    );
                                    Bus.instance.fire(
                                      PeopleChangedEvent(
                                          // person: personEntity,
                                          ),
                                    );
                                    Navigator.pop(context, result);
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          ButtonWidget(
                            buttonType: ButtonType.secondary,
                            buttonAction: ButtonAction.cancel,
                            labelText: S.of(context).cancel,
                            // labelText: collection.hasCover
                            //     ? S.of(context).resetToDefault
                            //     : S.of(context).cancel,
                            icon: null,
                            // icon: collection.hasCover
                            //     ? Icons.restore_outlined
                            //     : null,
                            onTap: () async {
                              Navigator.of(context).pop();
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
}
