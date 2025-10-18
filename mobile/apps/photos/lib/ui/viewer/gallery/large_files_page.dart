import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter/rendering.dart";
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
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class LargeFilesPagePage extends StatefulWidget {
  final String tagPrefix;
  final GalleryType appBarType;
  final GalleryType overlayType;
  static const int minLargeFileSize = 50 * 1024 * 1024;

  const LargeFilesPagePage({
    this.tagPrefix = "Uncategorized_page",
    this.appBarType = GalleryType.homepage,
    this.overlayType = GalleryType.homepage,
    super.key,
  });

  @override
  State<LargeFilesPagePage> createState() => _LargeFilesPagePageState();
}

class _LargeFilesPagePageState extends State<LargeFilesPagePage> {
  final _selectedFiles = SelectedFiles();
  bool _isCollapsed = false;
  bool _hasCollapsedOnce = false;
  bool _hasFilesSelected = false;
  Timer? _selectionTimer;

  @override
  void initState() {
    super.initState();
    _selectedFiles.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    final hasSelection = _selectedFiles.files.isNotEmpty;

    if (hasSelection && !_hasFilesSelected) {
      setState(() {
        _isCollapsed = false;
        _hasFilesSelected = true;
      });

      _selectionTimer?.cancel();
      _selectionTimer = Timer(const Duration(milliseconds: 10), () {});
    } else if (!hasSelection && _hasFilesSelected) {
      setState(() {
        _hasFilesSelected = false;
        _isCollapsed = false;
      });
      _selectionTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _selectedFiles.removeListener(_onSelectionChanged);
    _selectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is UserScrollNotification && _hasFilesSelected) {
          final shouldAllowCollapse =
              _selectionTimer == null || !_selectionTimer!.isActive;

          if (shouldAllowCollapse &&
              (!_hasCollapsedOnce || !_isCollapsed) &&
              (scrollInfo.direction == ScrollDirection.forward ||
                  scrollInfo.direction == ScrollDirection.reverse)) {
            Future.delayed(const Duration(milliseconds: 10), () {
              if (mounted && _hasFilesSelected) {
                setState(() {
                  _isCollapsed = true;
                  _hasCollapsedOnce = true;
                });
              }
            });
          }
        }
        return false;
      },
      child: Gallery(
        asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
          final List<EnteFile> allFiles =
              await SearchService.instance.getAllFilesForSearch();
          final Set<int> alreadyTracked = <int>{};

          final filesWithSize = <EnteFile>[];
          for (final file in allFiles) {
            if (file.isOwner &&
                file.isUploaded &&
                file.fileSize != null &&
                file.fileSize! > LargeFilesPagePage.minLargeFileSize) {
              if (!alreadyTracked.contains(file.uploadedFileID!)) {
                filesWithSize.add(file);
                alreadyTracked.add(file.uploadedFileID!);
              }
            }
          }
          // sort by file size descending
          filesWithSize.sort((a, b) => b.fileSize!.compareTo(a.fileSize!));
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
        tagPrefix: widget.tagPrefix,
        selectedFiles: _selectedFiles,
        sortAsyncFn: () => false,
        groupType: GroupType.size,
        initialFiles: null,
        albumName: AppLocalizations.of(context).viewLargeFiles,
      ),
    );
    return GalleryFilesState(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: AppBar(
            elevation: 0,
            centerTitle: false,
            title: Text(
              AppLocalizations.of(context).viewLargeFiles,
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
                widget.overlayType,
                _selectedFiles,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
