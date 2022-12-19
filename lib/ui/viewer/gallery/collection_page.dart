// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';

class CollectionPage extends StatefulWidget {
  final CollectionWithThumbnail c;
  final String tagPrefix;
  final GalleryType appBarType;
  final bool hasVerifiedLock;

  const CollectionPage(
    this.c, {
    this.tagPrefix = "collection",
    this.appBarType = GalleryType.ownedCollection,
    this.hasVerifiedLock = false,
    Key key,
  }) : super(key: key);

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final _selectedFiles = SelectedFiles();

  bool _isCollectionOwner = false;
  final GlobalKey shareButtonKey = GlobalKey();
  final ValueNotifier<double> _bottomPosition = ValueNotifier(-150.0);

  @override
  void initState() {
    _selectedFiles.addListener(_selectedFilesListener);
    _isCollectionOwner =
        Configuration.instance.getUserID() == widget.c.collection.owner.id;
    super.initState();
  }

  @override
  void dispose() {
    _selectedFiles.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(Object context) {
    if (widget.hasVerifiedLock == false && widget.c.collection.isHidden()) {
      return const EmptyState();
    }
    final initialFiles =
        widget.c.thumbnail != null ? [widget.c.thumbnail] : null;
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        final FileLoadResult result =
            await FilesDB.instance.getFilesInCollection(
          widget.c.collection.id,
          creationStartTime,
          creationEndTime,
          limit: limit,
          asc: asc,
        );
        // hide ignored files from home page UI
        final ignoredIDs = await IgnoredFilesService.instance.ignoredIDs;
        result.files.removeWhere(
          (f) =>
              f.uploadedFileID == null &&
              IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, f),
        );
        return result;
      },
      reloadEvent: Bus.instance
          .on<CollectionUpdatedEvent>()
          .where((event) => event.collectionID == widget.c.collection.id),
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: widget.tagPrefix,
      selectedFiles: _selectedFiles,
      initialFiles: initialFiles,
      albumName: widget.c.collection.name,
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          widget.appBarType,
          widget.c.collection.name,
          _selectedFiles,
          collection: widget.c.collection,
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          gallery,
          FileSelectionOverlayBar(
            widget.appBarType,
            _selectedFiles,
            collection: widget.c.collection,
          )
        ],
      ),
    );
  }

  _selectedFilesListener() {
    _selectedFiles.files.isNotEmpty
        ? _bottomPosition.value = 0.0
        : _bottomPosition.value = -150.0;
  }
}
