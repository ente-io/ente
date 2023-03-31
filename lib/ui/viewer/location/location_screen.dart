import 'dart:developer' as dev;
import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/services/files_service.dart";
import "package:photos/services/location_service.dart";
import "package:photos/states/location_state.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/text_input_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/location/radius_picker_widget.dart";

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final editNotifier = ValueNotifier(false);
    return LocationTagStateProvider(
      Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size(double.infinity, 48),
          child: TitleBarWidget(
            isSliver: false,
            isFlexibleSpaceDisabled: true,
            actionIcons: [
              IconButton(
                onPressed: () {
                  editNotifier.value = !editNotifier.value;
                },
                icon: const Icon(Icons.edit_rounded),
              )
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height - 102,
              width: double.infinity,
              child: LocationGalleryWidget(editNotifier),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationEditingWidget extends StatefulWidget {
  const LocationEditingWidget({super.key});

  @override
  State<LocationEditingWidget> createState() => _LocationEditingWidgetState();
}

class _LocationEditingWidgetState extends State<LocationEditingWidget> {
  final _selectedRadiusIndexNotifier = ValueNotifier(defaultRadiusValueIndex);

  @override
  void initState() {
    _selectedRadiusIndexNotifier.addListener(_selectedRadiusIndexListener);
    super.initState();
  }

  @override
  void dispose() {
    _selectedRadiusIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TextInputWidget(borderRadius: 2),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                color: Colors.amber,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4.5, 16, 4.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Center point",
                        style: textTheme.body,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Coordinates",
                        style: textTheme.miniMuted,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                color: getEnteColorScheme(context).strokeMuted,
              ),
            ],
          ),
          const SizedBox(height: 20),
          RadiusPickerWidget(_selectedRadiusIndexNotifier),
        ],
      ),
    );
  }

  void _selectedRadiusIndexListener() {
    InheritedLocationTagData.of(
      context,
    ).updateSelectedIndex(
      _selectedRadiusIndexNotifier.value,
    );
  }
}

class LocationGalleryWidget extends StatefulWidget {
  final ValueNotifier<bool> editNotifier;
  const LocationGalleryWidget(this.editNotifier, {super.key});

  @override
  State<LocationGalleryWidget> createState() => _LocationGalleryWidgetState();
}

class _LocationGalleryWidgetState extends State<LocationGalleryWidget> {
  late final Future<FileLoadResult> fileLoadResult;
  late Future<void> removeIgnoredFiles;
  late Widget galleryHeaderWidget;
  @override
  void initState() {
    fileLoadResult = FilesService.instance.fetchAllFilesWithLocationData();
    removeIgnoredFiles =
        FilesService.instance.removeIgnoredFiles(fileLoadResult);
    galleryHeaderWidget = GalleryHeaderWidget(
      widget.editNotifier,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("----------------");
    print(galleryHeaderWidget.hashCode);
    final selectedRadius = _selectedRadius();
    Future<FileLoadResult> filterFiles() async {
      final FileLoadResult result = await fileLoadResult;
      //wait for ignored files to be removed after init
      await removeIgnoredFiles;
      final stopWatch = Stopwatch()..start();
      final copyOfFiles = List<File>.from(result.files);
      copyOfFiles.removeWhere((f) {
        assert(
          f.location != null &&
              f.location!.latitude != null &&
              f.location!.longitude != null,
        );
        return !LocationService.instance.isFileInsideLocationTag(
          [63.5, -18.5], //pass the coordinates from the location tag here
          [f.location!.latitude!, f.location!.longitude!],
          selectedRadius,
        );
      });
      dev.log(
        "Time taken to get all files in a location tag: ${stopWatch.elapsedMilliseconds} ms",
      );
      stopWatch.stop();
      // widget.memoriesCountNotifier.value = copyOfFiles.length;
      // final limitedResults = copyOfFiles.take(galleryFilesLimit).toList();

      return Future.value(
        FileLoadResult(
          copyOfFiles,
          result.hasMore,
        ),
      );
    }

    return FutureBuilder(
      key: ValueKey(selectedRadius),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Gallery(
            loadingWidget: Column(
              children: [
                galleryHeaderWidget,
                const EnteLoadingWidget(),
              ],
            ),
            header: galleryHeaderWidget,
            asyncLoader: (
              creationStartTime,
              creationEndTime, {
              limit,
              asc,
            }) async {
              return snapshot.data as FileLoadResult;
            },
            tagPrefix: "location_gallery",
          );
        } else {
          // return const SizedBox.shrink();
          return galleryHeaderWidget;
        }
      },
      future: filterFiles(),
    );
  }

  int _selectedRadius() {
    return radiusValues[
        InheritedLocationTagData.of(context).selectedRadiusIndex];
  }
}

class GalleryHeaderWidget extends StatefulWidget {
  final ValueNotifier editNotifier;
  const GalleryHeaderWidget(this.editNotifier, {super.key});

  @override
  State<GalleryHeaderWidget> createState() => _GalleryHeaderWidgetState();
}

class _GalleryHeaderWidgetState extends State<GalleryHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    debugPrint("Building GalleryHeaderWidget --------------");
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder(
                  valueListenable: widget.editNotifier,
                  builder: (context, value, _) {
                    Widget child;
                    if (value as bool) {
                      child = SizedBox(
                        key: ValueKey(value),
                        width: double.infinity,
                        child: const TitleBarTitleWidget(
                          title: "Edit location",
                        ),
                      );
                    } else {
                      child = SizedBox(
                        key: ValueKey(value),
                        width: double.infinity,
                        child: const TitleBarTitleWidget(
                          title: "Location name",
                        ),
                      );
                    }
                    return AnimatedSwitcher(
                      switchInCurve: Curves.easeInExpo,
                      switchOutCurve: Curves.easeOutExpo,
                      duration: const Duration(milliseconds: 200),
                      child: child,
                    );
                  },
                ),
                Text(
                  "51 memories",
                  style: getEnteTextTheme(context).smallMuted,
                ),
              ],
            ),
          ),
          ValueListenableBuilder(
            valueListenable: widget.editNotifier,
            builder: (context, value, _) {
              return AnimatedCrossFade(
                firstCurve: Curves.easeInExpo,
                sizeCurve: Curves.easeInOutExpo,
                firstChild: const LocationEditingWidget(),
                secondChild: const SizedBox(width: double.infinity),
                crossFadeState: widget.editNotifier.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 300),
              );
            },
          )
        ],
      ),
    );
  }
}
