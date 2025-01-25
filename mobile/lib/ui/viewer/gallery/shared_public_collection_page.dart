import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/collection_meta_event.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/remote_sync_service.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/notification_widget.dart";
import "package:photos/ui/viewer/actions/file_selection_overlay_bar.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/toast_util.dart";

class SharedPublicCollectionPage extends StatefulWidget {
  final CollectionWithThumbnail c;
  final String tagPrefix;
  final List<EnteFile>? files;

  const SharedPublicCollectionPage(
    this.c, {
    this.tagPrefix = "shared_public_collection",
    super.key,
    this.files,
  }) : assert(
          !(files == null),
          'sharedLinkFiles cannot be empty',
        );

  @override
  State<SharedPublicCollectionPage> createState() =>
      _SharedPublicCollectionPageState();
}

class _SharedPublicCollectionPageState
    extends State<SharedPublicCollectionPage> {
  final _selectedFiles = SelectedFiles();
  final galleryType = GalleryType.sharedPublicCollection;
  final logger = Logger("SharedPublicCollectionPage");
  @override
  void initState() {
    super.initState();
    logger.info("Init SharedPublicCollectionPage");
  }

  @override
  void dispose() {
    _selectedFiles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.info("Building SharedPublicCollectionPage");
    final List<EnteFile>? initialFiles =
        widget.c.thumbnail != null ? [widget.c.thumbnail!] : null;
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        widget.files!.sort(
          (a, b) => b.creationTime!.compareTo(a.creationTime!),
        );

        return FileLoadResult(widget.files!, false);
      },
      reloadEvent: Bus.instance
          .on<CollectionUpdatedEvent>()
          .where((event) => event.collectionID == widget.c.collection.id),
      forceReloadEvents: [
        Bus.instance.on<CollectionMetaEvent>().where(
              (event) =>
                  event.id == widget.c.collection.id &&
                  event.type == CollectionMetaEventType.sortChanged,
            ),
      ],
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: widget.tagPrefix,
      selectedFiles: _selectedFiles,
      initialFiles: initialFiles,
      albumName: widget.c.collection.displayName,
      header: widget.c.collection.isJoinEnabled && flagService.internalUser
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: NotificationWidget(
                startIcon: Icons.people_outline,
                actionIcon: null,
                actionWidget: ButtonWidget(
                  buttonType: ButtonType.primary,
                  labelText: context.l10n.join,
                  buttonSize: ButtonSize.small,
                  shouldSurfaceExecutionStates: false,
                  onTap: _joinAlbum,
                ),
                text: context.l10n.joinAlbum,
                subText: widget.c.collection.isCollectEnabledForPublicLink()
                    ? context.l10n.joinAlbumSubtext
                    : context.l10n.joinAlbumSubtextViewer,
                type: NotificationType.notice,
                onTap: () async {},
              ),
            )
          : null,
      sortAsyncFn: () => widget.c.collection.pubMagicMetadata.asc ?? false,
    );

    return GalleryFilesState(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: GalleryAppBarWidget(
            galleryType,
            widget.c.collection.displayName,
            _selectedFiles,
            collection: widget.c.collection,
            files: widget.files,
          ),
        ),
        body: SelectionState(
          selectedFiles: _selectedFiles,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              gallery,
              FileSelectionOverlayBar(
                galleryType,
                _selectedFiles,
                collection: widget.c.collection,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _joinAlbum() async {
    final dialog = createProgressDialog(
      context,
      S.of(context).pleaseWait,
      isDismissible: true,
    );
    await dialog.show();
    try {
      await RemoteSyncService.instance
          .joinAndSyncCollection(context, widget.c.collection.id);
      final c =
          CollectionsService.instance.getCollectionByID(widget.c.collection.id);
      await dialog.hide();
      Navigator.of(context).pop();
      await routeToPage(
        context,
        CollectionPage(CollectionWithThumbnail(c!, null)),
      );
    } catch (e, s) {
      logger.severe("Failed to join collection", e, s);
      await dialog.hide();
      showToast(context, S.of(context).somethingWentWrong);
    }
  }
}
