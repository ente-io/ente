import 'package:flutter/material.dart';
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/ignored_files_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/bottom_of_title_bar_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/text_input_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";

showAddLocationSheet(BuildContext context, List<double> coordinates) {
  showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return AddLocationSheet(coordinates);
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

class AddLocationSheet extends StatefulWidget {
  final List<double> coordinates;
  const AddLocationSheet(this.coordinates, {super.key});

  @override
  State<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<AddLocationSheet> {
  final values = <double>[2, 10, 20, 40, 80, 200, 400, 1200];
  int selectedIndex = 4;
  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: BottomOfTitleBarWidget(
              title: TitleBarTitleWidget(title: "Add location"),
            ),
          ),
          Expanded(
            child: Gallery(
              header: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const TextInputWidget(
                          hintText: "Location name",
                          borderRadius: 2,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.fillFaint,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(2)),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Text(
                                      values[selectedIndex].toInt().toString(),
                                      style: values[selectedIndex] != 1200
                                          ? textTheme.largeBold
                                          : textTheme.bodyBold,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      "km",
                                      style: textTheme.miniMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Radius", style: textTheme.body),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 12,
                                      child: SliderTheme(
                                        data: SliderThemeData(
                                          overlayColor: Colors.transparent,
                                          thumbColor: strokeSolidMutedLight,
                                          activeTrackColor:
                                              strokeSolidMutedLight,
                                          inactiveTrackColor:
                                              colorScheme.strokeFaint,
                                          activeTickMarkColor:
                                              colorScheme.strokeMuted,
                                          inactiveTickMarkColor:
                                              strokeSolidMutedLight,
                                          trackShape: CustomTrackShape(),
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                            enabledThumbRadius: 6,
                                            pressedElevation: 0,
                                            elevation: 0,
                                          ),
                                          tickMarkShape:
                                              const RoundSliderTickMarkShape(
                                            tickMarkRadius: 1,
                                          ),
                                        ),
                                        child: RepaintBoundary(
                                          child: Slider(
                                            value: selectedIndex.toDouble(),
                                            onChanged: (value) {
                                              setState(() {
                                                selectedIndex = value.toInt();
                                              });
                                            },
                                            min: 0,
                                            max: values.length - 1,
                                            divisions: values.length - 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "A location groups all photos that were taken within some radius of a photo",
                          style: textTheme.smallMuted,
                        ),
                      ],
                    ),
                  ),
                  const DividerWidget(
                    dividerType: DividerType.solid,
                    padding: EdgeInsets.symmetric(vertical: 24),
                  ),
                ],
              ),
              asyncLoader: (
                creationStartTime,
                creationEndTime, {
                limit,
                asc,
              }) async {
                final ownerID = Configuration.instance.getUserID();
                final hasSelectedAllForBackup =
                    Configuration.instance.hasSelectedAllFoldersForBackup();
                final collectionsToHide =
                    CollectionsService.instance.collectionsHiddenFromTimeline();
                FileLoadResult result;
                if (hasSelectedAllForBackup) {
                  result = await FilesDB.instance.getAllLocalAndUploadedFiles(
                    creationStartTime,
                    creationEndTime,
                    ownerID!,
                    limit: limit,
                    asc: asc,
                    ignoredCollectionIDs: collectionsToHide,
                    onlyFilesWithLocation: true,
                  );
                } else {
                  result = await FilesDB.instance.getAllPendingOrUploadedFiles(
                    creationStartTime,
                    creationEndTime,
                    ownerID!,
                    limit: limit,
                    asc: asc,
                    ignoredCollectionIDs: collectionsToHide,
                    onlyFilesWithLocation: true,
                  );
                }

                // hide ignored files from home page UI
                final ignoredIDs =
                    await IgnoredFilesService.instance.ignoredIDs;
                result.files.removeWhere(
                  (f) =>
                      f.uploadedFileID == null &&
                      IgnoredFilesService.instance
                          .shouldSkipUpload(ignoredIDs, f),
                );
                return result;
              },
              tagPrefix: "Add location",
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const trackHeight = 2.0;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(0, 0, trackWidth, trackHeight);
  }
}
