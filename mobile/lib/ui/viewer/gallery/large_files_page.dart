import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/collection_meta_event.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/services/search_service.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class LargeFilesPagePage extends StatelessWidget {
  final String tagPrefix;
  final GalleryType appBarType;
  final GalleryType overlayType;
  final _selectedFiles = SelectedFiles();
  static const int minLargeFileSize = 50 * 1024 * 1024;

  LargeFilesPagePage({
    this.tagPrefix = "Uncategorized_page",
    this.appBarType = GalleryType.homepage,
    this.overlayType = GalleryType.homepage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        final List<EnteFile> allFiles =
            await SearchService.instance.getAllFiles();
        final Set<int> alreadyTracked = <int>{};

        final filesWithSize = <EnteFile>[];
        for (final file in allFiles) {
          if (file.isOwner &&
              file.isUploaded &&
              file.fileSize != null &&
              file.fileSize! > minLargeFileSize) {
            if (!alreadyTracked.contains(file.uploadedFileID!)) {
              filesWithSize.add(file);
              alreadyTracked.add(file.uploadedFileID!);
            }
          }
        }
        final FileLoadResult result = FileLoadResult(filesWithSize, false);
        return result;
      },
      reloadEvent: Bus.instance.on<CollectionUpdatedEvent>(),
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      forceReloadEvents: [
        Bus.instance.on<CollectionMetaEvent>(),
      ],
      tagPrefix: tagPrefix,
      selectedFiles: _selectedFiles,
      sortAsyncFn: () => false,
      groupType: GroupType.size,
      initialFiles: null,
      albumName: S.of(context).viewLargeFiles,
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          elevation: 0,
          centerTitle: false,
          title: Text(
            S.of(context).viewLargeFiles,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: SelectionState(
        selectedFiles: _selectedFiles,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            gallery,
            FileSelectionOverlayBar(
              overlayType,
              _selectedFiles,
            ),
          ],
        ),
      ),
    );
  }
}
