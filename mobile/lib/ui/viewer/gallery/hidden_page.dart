import "dart:async";

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import "package:photos/events/collection_updated_event.dart";
import 'package:photos/events/files_updated_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/hidden_service.dart";
import "package:photos/ui/collections/album/horizontal_list.dart";
import "package:photos/ui/common/loading_widget.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/empty_hidden_widget.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class HiddenPage extends StatefulWidget {
  final String tagPrefix;
  final GalleryType appBarType;
  final GalleryType overlayType;

  const HiddenPage({
    this.tagPrefix = "hidden_page",
    this.appBarType = GalleryType.hiddenSection,
    this.overlayType = GalleryType.hiddenSection,
    Key? key,
  }) : super(key: key);

  @override
  State<HiddenPage> createState() => _HiddenPageState();
}

class _HiddenPageState extends State<HiddenPage> {
  int? _defaultHiddenCollectionId;
  final _hiddenCollectionsExcludingDefault = <Collection>[];
  late StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;

  @override
  void initState() {
    super.initState();
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      setState(() {
        getHiddenCollections();
      });
    });
    getHiddenCollections();
  }

  getHiddenCollections() {
    final hiddenCollections =
        CollectionsService.instance.getHiddenCollections();
    CollectionsService.instance
        .getDefaultHiddenCollection()
        .then((defaultHiddenCollection) {
      setState(() {
        _hiddenCollectionsExcludingDefault.clear();
        _defaultHiddenCollectionId = defaultHiddenCollection.id;
        for (Collection hiddenColleciton in hiddenCollections) {
          if (hiddenColleciton.id != defaultHiddenCollection.id) {
            _hiddenCollectionsExcludingDefault.add(hiddenColleciton);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _collectionUpdatesSubscription.cancel();
    super.dispose();
  }

  final _selectedFiles = SelectedFiles();

  @override
  Widget build(BuildContext context) {
    if (_defaultHiddenCollectionId == null) {
      return const EnteLoadingWidget();
    }
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getFilesInCollections(
          [_defaultHiddenCollectionId!],
          creationStartTime,
          creationEndTime,
          Configuration.instance.getUserID()!,
          limit: limit,
          asc: asc,
        );
      },
      reloadEvent: Bus.instance.on<FilesUpdatedEvent>().where(
            (event) =>
                event.updatedFiles.firstWhereOrNull(
                  (element) => element.uploadedFileID != null,
                ) !=
                null,
          ),
      removalEventTypes: const {
        EventType.unhide,
        EventType.deletedFromEverywhere,
        EventType.deletedFromRemote,
      },
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
      emptyState: _hiddenCollectionsExcludingDefault.isEmpty
          ? const EmptyHiddenWidget()
          : const SizedBox.shrink(),
      header: AlbumHorizontalList(
        () async {
          return _hiddenCollectionsExcludingDefault;
        },
        hasVerifiedLock: true,
      ),
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          widget.appBarType,
          S.of(context).hidden,
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
    );
  }
}
