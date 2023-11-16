import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/search/search_result.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';

class SearchResultPage extends StatelessWidget {
  final SearchResult searchResult;
  final String tagPrefix;

  final _selectedFiles = SelectedFiles();
  static const GalleryType appBarType = GalleryType.searchResults;
  static const GalleryType overlayType = GalleryType.searchResults;

  SearchResultPage(
    this.searchResult, {
    this.tagPrefix = "",
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<EnteFile> files = searchResult.resultFiles();
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        final result = files
            .where(
              (file) =>
                  file.creationTime! >= creationStartTime &&
                  file.creationTime! <= creationEndTime,
            )
            .toList();
        return Future.value(
          FileLoadResult(
            result,
            result.length < files.length,
          ),
        );
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
      },
      tagPrefix: tagPrefix + searchResult.heroTag(),
      selectedFiles: _selectedFiles,
      initialFiles: [searchResult.resultFiles().first],
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          appBarType,
          searchResult.name(),
          _selectedFiles,
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          gallery,
          FileSelectionOverlayBar(
            overlayType,
            _selectedFiles,
          ),
        ],
      ),
    );
  }
}
