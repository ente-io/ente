import "dart:async";

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import "package:flutter/rendering.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/metadata/common_keys.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/filter/db_filters.dart";
import "package:photos/ui/collections/album/horizontal_list.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import "package:photos/ui/viewer/gallery/empty_state.dart";
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class ArchivePage extends StatefulWidget {
  final String tagPrefix;
  final GalleryType appBarType;
  final GalleryType overlayType;

  const ArchivePage({
    this.tagPrefix = "archived_page",
    this.appBarType = GalleryType.archive,
    this.overlayType = GalleryType.archive,
    super.key,
  });

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
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
    final Set<int> hiddenCollectionIDs =
        CollectionsService.instance.getHiddenCollectionIds();
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
        asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
          return FilesDB.instance.getAllPendingOrUploadedFiles(
            creationStartTime,
            creationEndTime,
            Configuration.instance.getUserID()!,
            visibility: archiveVisibility,
            limit: limit,
            asc: asc,
            filterOptions: DBFilterOptions(
              hideIgnoredForUpload: true,
              dedupeUploadID: true,
              ignoredCollectionIDs: hiddenCollectionIDs,
            ),
            applyOwnerCheck: true,
          );
        },
        reloadEvent: Bus.instance.on<FilesUpdatedEvent>().where(
              (event) =>
                  event.updatedFiles.firstWhereOrNull(
                    (element) => element.uploadedFileID != null,
                  ) !=
                  null,
            ),
        removalEventTypes: const {EventType.unarchived},
        forceReloadEvents: [
          Bus.instance.on<FilesUpdatedEvent>().where(
                (event) =>
                    event.updatedFiles.firstWhereOrNull(
                      (element) => element.uploadedFileID != null,
                    ) !=
                    null,
              ),
        ],
        tagPrefix: widget.tagPrefix,
        selectedFiles: _selectedFiles,
        initialFiles: null,
        emptyState: EmptyState(
          text: AppLocalizations.of(context).youDontHaveAnyArchivedItems,
        ),
        header: AlbumHorizontalList(
          CollectionsService.instance.getArchivedCollection,
        ),
      ),
    );
    return GalleryFilesState(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: GalleryAppBarWidget(
            widget.appBarType,
            AppLocalizations.of(context).archive,
            _selectedFiles,
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
