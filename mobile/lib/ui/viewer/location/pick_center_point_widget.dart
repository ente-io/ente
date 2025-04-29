import "dart:math";

import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/filter/db_filters.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/bottom_of_title_bar_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/notification_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";

Future<Location?> showPickCenterPointSheet(
  BuildContext context, {
  String? locationTagName,
}) async {
  return await showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return PickCenterPointWidget(locationTagName);
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

class PickCenterPointWidget extends StatelessWidget {
  final String? locationTagName;

  const PickCenterPointWidget(
    this.locationTagName, {
    super.key,
  });

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
                            title: S.of(context).pickCenterPoint,
                          ),
                          caption: locationTagName ?? S.of(context).newLocation,
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
                                final collectionsToHide = CollectionsService
                                    .instance
                                    .archivedOrHiddenCollectionIds();
                                FileLoadResult result;
                                result = await FilesDB.instance
                                    .fetchAllUploadedAndSharedFilesWithLocation(
                                  galleryLoadStartTime,
                                  galleryLoadEndTime,
                                  limit: null,
                                  asc: false,
                                  filterOptions: DBFilterOptions(
                                    ignoredCollectionIDs: collectionsToHide,
                                    hideIgnoredForUpload: true,
                                  ),
                                );
                                return result;
                              },
                              reloadEvent:
                                  Bus.instance.on<LocalPhotosUpdatedEvent>(),
                              tagPrefix: "pick_center_point_gallery",
                              selectedFiles: selectedFiles,
                              limitSelectionToOne: true,
                              showSelectAllByDefault: false,
                              header: const Padding(
                                padding: EdgeInsets.all(10),
                                child: NotificationTipWidget(
                                  "You can also add a location centered on a photo from the photo's info screen",
                                ),
                              ),
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
                                    final selectedLocation =
                                        selectedFiles.files.first.location;
                                    Navigator.pop(context, selectedLocation);
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
