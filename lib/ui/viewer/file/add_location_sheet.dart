import 'package:flutter/material.dart';
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/location_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/bottom_of_title_bar_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/text_input_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";

showAddLocationSheet(BuildContext context, List<double> coordinates) {
  showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return LocationTagDataStateProvider(
          coordinates, const AddLocationSheet());
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

class LocationTagDataStateProvider extends StatefulWidget {
  final List<double> coordinates;
  final Widget child;
  const LocationTagDataStateProvider(this.coordinates, this.child, {super.key});

  @override
  State<LocationTagDataStateProvider> createState() =>
      _LocationTagDataStateProviderState();
}

class _LocationTagDataStateProviderState
    extends State<LocationTagDataStateProvider> {
  int selectedIndex = 4;
  late List<double> coordinates;
  @override
  void initState() {
    coordinates = widget.coordinates;
    super.initState();
  }

  void _updateSelectedIndex(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedLocationTagData(
      selectedIndex,
      coordinates,
      _updateSelectedIndex,
      child: widget.child,
    );
  }
}

class InheritedLocationTagData extends InheritedWidget {
  final int selectedIndex;
  final List<double> coordinates;
  final VoidCallbackParamInt updateSelectedIndex;
  const InheritedLocationTagData(
    this.selectedIndex,
    this.coordinates,
    this.updateSelectedIndex, {
    required super.child,
    super.key,
  });

  static InheritedLocationTagData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedLocationTagData>()!;
  }

  @override
  bool updateShouldNotify(InheritedLocationTagData oldWidget) {
    return oldWidget.selectedIndex != selectedIndex;
  }
}

class AddLocationSheet extends StatefulWidget {
  const AddLocationSheet({super.key});

  @override
  State<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<AddLocationSheet> {
  ValueNotifier<int?> memoriesCountNotifier = ValueNotifier(null);
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
              key: ValueKey(_selectedRadius()),
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
                        const RadiusPickerWidget(),
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
                    padding: EdgeInsets.only(top: 24, bottom: 20),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ValueListenableBuilder(
                        valueListenable: memoriesCountNotifier,
                        builder: (context, value, _) {
                          Widget widget;
                          if (value == null) {
                            widget = RepaintBoundary(
                              child: EnteLoadingWidget(
                                size: 14,
                                color: colorScheme.strokeMuted,
                                alignment: Alignment.centerLeft,
                                padding: 3,
                              ),
                            );
                          } else {
                            widget = Text(
                              value == 1 ? "1 memory" : "$value memories",
                              style: textTheme.body,
                            );
                          }
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeInOutExpo,
                              switchOutCurve: Curves.easeInOutExpo,
                              child: widget,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                result.files.removeWhere((f) {
                  assert(
                    f.location != null &&
                        f.location!.latitude != null &&
                        f.location!.longitude != null,
                  );
                  return f.uploadedFileID == null &&
                          IgnoredFilesService.instance
                              .shouldSkipUpload(ignoredIDs, f) ||
                      !LocationService.instance.isFileInsideLocationTag(
                        InheritedLocationTagData.of(context).coordinates,
                        [f.location!.latitude!, f.location!.longitude!],
                        _selectedRadius().toInt(),
                      );
                });
                if (!result.hasMore) {
                  memoriesCountNotifier.value = result.files.length;
                }
                return result;
              },
              tagPrefix: "Add location",
              shouldCollateFilesByDay: false,
            ),
          ),
        ],
      ),
    );
  }

  double _selectedRadius() {
    return radiusValues[InheritedLocationTagData.of(context).selectedIndex];
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

class RadiusPickerWidget extends StatelessWidget {
  const RadiusPickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: colorScheme.fillFaint,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
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
                  _selectedRadius(context).toInt().toString(),
                  style: _selectedRadius(context) != 1200
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      activeTrackColor: strokeSolidMutedLight,
                      inactiveTrackColor: colorScheme.strokeFaint,
                      activeTickMarkColor: colorScheme.strokeMuted,
                      inactiveTickMarkColor: strokeSolidMutedLight,
                      trackShape: CustomTrackShape(),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                        pressedElevation: 0,
                        elevation: 0,
                      ),
                      tickMarkShape: const RoundSliderTickMarkShape(
                        tickMarkRadius: 1,
                      ),
                    ),
                    child: RepaintBoundary(
                      child: Slider(
                        value: InheritedLocationTagData.of(
                          context,
                        ).selectedIndex.toDouble(),
                        onChanged: (value) {
                          InheritedLocationTagData.of(
                            context,
                          ).updateSelectedIndex(
                            value.toInt(),
                          );
                        },
                        min: 0,
                        max: radiusValues.length - 1,
                        divisions: radiusValues.length - 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _selectedRadius(BuildContext context) {
    return radiusValues[InheritedLocationTagData.of(context).selectedIndex];
  }
}
