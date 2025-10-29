import "dart:async";

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/gallery_boundaries_provider.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class JumpToDateGallery extends StatefulWidget {
  final EnteFile fileToJumpTo;
  final String tagPrefix;

  static const GalleryType appBarType = GalleryType.searchResults;
  static const GalleryType overlayType = GalleryType.searchResults;

  const JumpToDateGallery({
    required this.fileToJumpTo,
    this.tagPrefix = "jump_to_date",
    super.key,
  });

  @override
  State<JumpToDateGallery> createState() => _JumpToDateGalleryState();
}

class _JumpToDateGalleryState extends State<JumpToDateGallery> {
  final _selectedFiles = SelectedFiles();
  late final List<EnteFile> files;
  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdatedEvent;
  bool _isLoadingFiles = true;

  @override
  void initState() {
    super.initState();
    files = [];
    _filesUpdatedEvent =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      if (event.type == EventType.deletedFromDevice ||
          event.type == EventType.deletedFromEverywhere ||
          event.type == EventType.deletedFromRemote ||
          event.type == EventType.hide) {
        for (var updatedFile in event.updatedFiles) {
          files.remove(updatedFile);
        }
        setState(() {});
      }
    });

    // Load files asynchronously
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final allFiles =
        await SearchService.instance.getAllFilesForHierarchicalSearch();
    setState(() {
      files.clear();
      files.addAll(allFiles);
      _isLoadingFiles = false;
    });
  }

  @override
  void dispose() {
    _filesUpdatedEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GalleryBoundariesProvider(
      child: GalleryFilesState(
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(90.0),
            child: GalleryAppBarWidget(
              JumpToDateGallery.appBarType,
              "Jump to Date",
              _selectedFiles,
            ),
          ),
          body: _isLoadingFiles
              ? const EnteLoadingWidget()
              : SelectionState(
                  selectedFiles: _selectedFiles,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Gallery(
                        asyncLoader: (
                          creationStartTime,
                          creationEndTime, {
                          limit,
                          asc,
                        }) {
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
                          EventType.hide,
                        },
                        tagPrefix: widget.tagPrefix,
                        selectedFiles: _selectedFiles,
                        enableFileGrouping: true,
                        fileToJumpTo: widget.fileToJumpTo,
                      ),
                      FileSelectionOverlayBar(
                        JumpToDateGallery.overlayType,
                        _selectedFiles,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
