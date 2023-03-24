import "dart:developer" as dev;

import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/location_service.dart";
import "package:photos/states/add_location_state.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/utils/local_settings.dart";

class AddLocationGalleryWidget extends StatefulWidget {
  final ValueNotifier<int?> memoriesCountNotifier;
  const AddLocationGalleryWidget(this.memoriesCountNotifier, {super.key});

  @override
  State<AddLocationGalleryWidget> createState() =>
      _AddLocationGalleryWidgetState();
}

class _AddLocationGalleryWidgetState extends State<AddLocationGalleryWidget> {
  late final Future<FileLoadResult> fileLoadResult;
  late Future<void> removeIgnoredFiles;
  double heightOfGallery = 0;

  @override
  void initState() {
    final ownerID = Configuration.instance.getUserID();
    final hasSelectedAllForBackup =
        Configuration.instance.hasSelectedAllFoldersForBackup();
    final collectionsToHide =
        CollectionsService.instance.collectionsHiddenFromTimeline();
    if (hasSelectedAllForBackup) {
      fileLoadResult = FilesDB.instance.getAllLocalAndUploadedFiles(
        galleryLoadStartTime,
        galleryLoadEndTime,
        ownerID!,
        limit: null,
        asc: true,
        ignoredCollectionIDs: collectionsToHide,
        onlyFilesWithLocation: true,
      );
    } else {
      fileLoadResult = FilesDB.instance.getAllPendingOrUploadedFiles(
        galleryLoadStartTime,
        galleryLoadEndTime,
        ownerID!,
        limit: null,
        asc: true,
        ignoredCollectionIDs: collectionsToHide,
        onlyFilesWithLocation: true,
      );
    }
    removeIgnoredFiles = _removeIgnoredFiles(fileLoadResult);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRadius = _selectedRadius();
    late final int memoryCount;
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
          InheritedLocationTagData.of(context).coordinates,
          [f.location!.latitude!, f.location!.longitude!],
          selectedRadius,
        );
      });
      dev.log(
        "Time taken to get all files in a location tag: ${stopWatch.elapsedMilliseconds} ms",
      );
      stopWatch.stop();
      memoryCount = copyOfFiles.length;
      widget.memoriesCountNotifier.value = copyOfFiles.length;
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
          return SizedBox(
            height: _galleryHeight(memoryCount),
            child: Gallery(
              key: ValueKey(selectedRadius),
              loadingWidget: const SizedBox.shrink(),
              disableScroll: true,
              asyncLoader: (
                creationStartTime,
                creationEndTime, {
                limit,
                asc,
              }) async {
                return snapshot.data as FileLoadResult;
              },
              tagPrefix: "Add location",
              shouldCollateFilesByDay: false,
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
      future: filterFiles(),
    );
  }

  int _selectedRadius() {
    return radiusValues[
        InheritedLocationTagData.of(context).selectedRadiusIndex];
  }

  Future<void> _removeIgnoredFiles(Future<FileLoadResult> result) async {
    final ignoredIDs = await IgnoredFilesService.instance.ignoredIDs;
    (await result).files.removeWhere(
          (f) =>
              f.uploadedFileID == null &&
              IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, f),
        );
  }

  double _galleryHeight(int memoryCount) {
    final photoGridSize = LocalSettings.instance.getPhotoGridSize();
    final totalWhiteSpaceBetweenPhotos =
        galleryGridSpacing * (photoGridSize - 1);

    final thumbnailHeight =
        ((MediaQuery.of(context).size.width - totalWhiteSpaceBetweenPhotos) /
            photoGridSize);

    final numberOfRows = (memoryCount / photoGridSize).ceil();

    final galleryHeight = (thumbnailHeight * numberOfRows) +
        (galleryGridSpacing * (numberOfRows - 1));
    return galleryHeight + 120;
  }
}
