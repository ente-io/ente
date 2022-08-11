import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/user_logged_out_event.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/collections/device_folders_grid_view_widget.dart';
import 'package:photos/ui/collections/ente_section_title.dart';
import 'package:photos/ui/collections/hidden_collections_button_widget.dart';
import 'package:photos/ui/collections/remote_collections_grid_view_widget.dart';
import 'package:photos/ui/collections/section_title.dart';
import 'package:photos/ui/collections/trash_button_widget.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/gallery/device_all_page.dart';
import 'package:photos/ui/viewer/gallery/empte_state.dart';
import 'package:photos/utils/local_settings.dart';
import 'package:photos/utils/navigation_util.dart';

class CollectionsGalleryWidget extends StatefulWidget {
  const CollectionsGalleryWidget({Key key}) : super(key: key);

  @override
  State<CollectionsGalleryWidget> createState() =>
      _CollectionsGalleryWidgetState();
}

class _CollectionsGalleryWidgetState extends State<CollectionsGalleryWidget>
    with AutomaticKeepAliveClientMixin {
  final _logger = Logger("CollectionsGallery");
  StreamSubscription<LocalPhotosUpdatedEvent> _localFilesSubscription;
  StreamSubscription<CollectionUpdatedEvent> _collectionUpdatesSubscription;
  StreamSubscription<BackupFoldersUpdatedEvent> _backupFoldersUpdatedEvent;
  StreamSubscription<UserLoggedOutEvent> _loggedOutEvent;
  AlbumSortKey sortKey;
  String _loadReason = "init";

  @override
  void initState() {
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _loadReason = (LocalPhotosUpdatedEvent).toString();
      setState(() {});
    });
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      _loadReason = (CollectionUpdatedEvent).toString();
      setState(() {});
    });
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((event) {
      _loadReason = (UserLoggedOutEvent).toString();
      setState(() {});
    });
    _backupFoldersUpdatedEvent =
        Bus.instance.on<BackupFoldersUpdatedEvent>().listen((event) {
      _loadReason = (BackupFoldersUpdatedEvent).toString();
      setState(() {});
    });
    sortKey = LocalSettings.instance.albumSortKey();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _logger.info("Building, trigger: $_loadReason");
    return FutureBuilder<CollectionItems>(
      future: _getCollections(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _getCollectionsGalleryWidget(snapshot.data);
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }

  Future<CollectionItems> _getCollections() async {
    final filesDB = FilesDB.instance;
    final collectionsService = CollectionsService.instance;
    final userID = Configuration.instance.getUserID();
    final List<DeviceFolder> folders = [];
    final latestLocalFiles = await filesDB.getLatestLocalFiles();
    for (final file in latestLocalFiles) {
      folders.add(DeviceFolder(file.deviceFolder, file.deviceFolder, file));
    }
    folders.sort(
      (first, second) =>
          second.thumbnail.creationTime.compareTo(first.thumbnail.creationTime),
    );

    final List<CollectionWithThumbnail> collectionsWithThumbnail = [];
    final latestCollectionFiles =
        await collectionsService.getLatestCollectionFiles();
    for (final file in latestCollectionFiles) {
      final c = collectionsService.getCollectionByID(file.collectionID);
      if (c.owner.id == userID) {
        collectionsWithThumbnail.add(CollectionWithThumbnail(c, file));
      }
    }
    collectionsWithThumbnail.sort(
      (first, second) {
        if (sortKey == AlbumSortKey.albumName) {
          // alphabetical ASC order
          return first.collection.name.compareTo(second.collection.name);
        } else if (sortKey == AlbumSortKey.newestPhoto) {
          return second.thumbnail.creationTime
              .compareTo(first.thumbnail.creationTime);
        } else {
          return second.collection.updationTime
              .compareTo(first.collection.updationTime);
        }
      },
    );
    return CollectionItems(folders, collectionsWithThumbnail);
  }

  Widget _getCollectionsGalleryWidget(CollectionItems items) {
    final TextStyle trashAndHiddenTextStyle = Theme.of(context)
        .textTheme
        .subtitle1
        .copyWith(
          color: Theme.of(context).textTheme.subtitle1.color.withOpacity(0.5),
        );

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SectionTitle("On device"),
                Platform.isAndroid
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: Text("View all"),
                        ),
                        onTap: () => routeToPage(context, DeviceAllPage()),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            items.folders.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: EmptyState(),
                  )
                : DeviceFoldersGridViewWidget(items.folders),
            const Padding(padding: EdgeInsets.all(4)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const EnteSectionTitle(),
                _sortMenu(),
              ],
            ),
            const SizedBox(height: 12),
            Configuration.instance.hasConfiguredAccount()
                ? RemoteCollectionsGridViewWidget(items.collections)
                : const EmptyState(),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TrashButtonWidget(trashAndHiddenTextStyle),
                  const SizedBox(height: 12),
                  HiddenCollectionsButtonWidget(trashAndHiddenTextStyle),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 36)),
          ],
        ),
      ),
    );
  }

  Widget _sortMenu() {
    Text sortOptionText(AlbumSortKey key) {
      String text = key.toString();
      switch (key) {
        case AlbumSortKey.albumName:
          text = "Name";
          break;
        case AlbumSortKey.newestPhoto:
          text = "Newest";
          break;
        case AlbumSortKey.lastUpdated:
          text = "Last updated";
      }
      return Text(
        text,
        style: Theme.of(context).textTheme.subtitle1.copyWith(
              fontSize: 14,
              color: Theme.of(context).iconTheme.color.withOpacity(0.7),
            ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: PopupMenuButton(
        offset: const Offset(10, 50),
        initialValue: sortKey?.index ?? 0,
        child: Align(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 5.0),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.sort,
                  color: Theme.of(context).iconTheme.color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        onSelected: (int index) async {
          sortKey = AlbumSortKey.values[index];
          await LocalSettings.instance.setAlbumSortKey(sortKey);
          setState(() {});
        },
        itemBuilder: (context) {
          return List.generate(AlbumSortKey.values.length, (index) {
            return PopupMenuItem(
              value: index,
              child: sortOptionText(AlbumSortKey.values[index]),
            );
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _localFilesSubscription.cancel();
    _collectionUpdatesSubscription.cancel();
    _loggedOutEvent.cancel();
    _backupFoldersUpdatedEvent.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
