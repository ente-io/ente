import 'dart:developer' as dev;
import "package:flutter/material.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/services/files_service.dart";
import "package:photos/services/location_service.dart";
import "package:photos/states/location_screen_state.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/location/edit_location_sheet.dart";

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 48),
        child: TitleBarWidget(
          isSliver: false,
          isFlexibleSpaceDisabled: true,
          actionIcons: [
            IconButton(
              onPressed: () {
                showEditLocationSheet(context, [63.5, -18.5], () {});
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
            child: const LocationGalleryWidget(),
          ),
        ],
      ),
    );
  }
}

class LocationGalleryWidget extends StatefulWidget {
  const LocationGalleryWidget({super.key});

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
    galleryHeaderWidget = const GalleryHeaderWidget();
    super.initState();
  }

  @override
  void dispose() {
    InheritedLocationScreenState.memoryCountNotifier.value = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Todo: get radius of location tag here.
    final selectedRadius =
        InheritedLocationScreenState.of(context).locationTag.radius;
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
      InheritedLocationScreenState.memoryCountNotifier.value =
          copyOfFiles.length;

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
                EnteLoadingWidget(
                  color: getEnteColorScheme(context).strokeMuted,
                ),
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
          return Column(
            children: [
              galleryHeaderWidget,
              const Expanded(
                child: EnteLoadingWidget(),
              ),
            ],
          );
        }
      },
      future: filterFiles(),
    );
  }
}

class GalleryHeaderWidget extends StatefulWidget {
  const GalleryHeaderWidget({super.key});

  @override
  State<GalleryHeaderWidget> createState() => _GalleryHeaderWidgetState();
}

class _GalleryHeaderWidgetState extends State<GalleryHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final locationName =
        InheritedLocationScreenState.of(context).locationTag.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              key: ValueKey(locationName),
              width: double.infinity,
              child: TitleBarTitleWidget(
                title: locationName,
              ),
            ),
            ValueListenableBuilder(
              valueListenable: InheritedLocationScreenState.memoryCountNotifier,
              builder: (context, value, _) {
                if (value == null) {
                  return RepaintBoundary(
                    child: EnteLoadingWidget(
                      size: 10,
                      color: getEnteColorScheme(context).strokeMuted,
                      alignment: Alignment.centerLeft,
                      padding: 5,
                    ),
                  );
                } else {
                  return Text(
                    value == 1 ? "1 memory" : "$value memories",
                    style: getEnteTextTheme(context).smallMuted,
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
