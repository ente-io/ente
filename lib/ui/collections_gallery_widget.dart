import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/events/user_logged_out_event.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/archive_page.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/ui/viewer/gallery/device_all_page.dart';
import 'package:photos/ui/viewer/gallery/device_folder_page.dart';
import 'package:photos/ui/viewer/gallery/empte_state.dart';
import 'package:photos/ui/viewer/gallery/trash_page.dart';
import 'package:photos/utils/local_settings.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';

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
    const double horizontalPaddingOfGridRow = 16;
    const double crossAxisSpacingOfGrid = 9;
    final TextStyle trashAndHiddenTextStyle = Theme.of(context)
        .textTheme
        .subtitle1
        .copyWith(
          color: Theme.of(context).textTheme.subtitle1.color.withOpacity(0.5),
        );
    Size size = MediaQuery.of(context).size;
    int albumsCountInOneRow = max(size.width ~/ 220.0, 2);
    final double sideOfThumbnail = (size.width / albumsCountInOneRow) -
        horizontalPaddingOfGridRow -
        ((crossAxisSpacingOfGrid / 2) * (albumsCountInOneRow - 1));
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
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      height: 170,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: items.folders.isEmpty
                            ? const EmptyState()
                            : ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                                physics: const ScrollPhysics(),
                                // to disable GridView's scrolling
                                itemBuilder: (context, index) {
                                  return DeviceFolderIcon(items.folders[index]);
                                },
                                itemCount: items.folders.length,
                              ),
                      ),
                    ),
                  ),
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
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const ScrollPhysics(),
                      // to disable GridView's scrolling
                      itemBuilder: (context, index) {
                        return _buildCollection(
                          context,
                          items.collections,
                          index,
                        );
                      },
                      itemCount: items.collections.length + 1,
                      // To include the + button
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: albumsCountInOneRow,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: crossAxisSpacingOfGrid,
                        childAspectRatio:
                            sideOfThumbnail / (sideOfThumbnail + 24),
                      ), //24 is height of album title
                    ),
                  )
                : const EmptyState(),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(0),
                      side: BorderSide(
                        width: 0.5,
                        color:
                            Theme.of(context).iconTheme.color.withOpacity(0.24),
                      ),
                    ),
                    child: SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                const Padding(padding: EdgeInsets.all(6)),
                                FutureBuilder<int>(
                                  future: TrashDB.instance.count(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data > 0) {
                                      return RichText(
                                        text: TextSpan(
                                          style: trashAndHiddenTextStyle,
                                          children: [
                                            TextSpan(
                                              text: "Trash",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle1,
                                            ),
                                            const TextSpan(text: "  \u2022  "),
                                            TextSpan(
                                              text: snapshot.data.toString(),
                                            ),
                                            //need to query in db and bring this value
                                          ],
                                        ),
                                      );
                                    } else {
                                      return RichText(
                                        text: TextSpan(
                                          style: trashAndHiddenTextStyle,
                                          children: [
                                            TextSpan(
                                              text: "Trash",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle1,
                                            ),
                                            //need to query in db and bring this value
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                    onPressed: () async {
                      routeToPage(
                        context,
                        TrashPage(),
                      );
                    },
                  ),
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

  Widget _buildCollection(
    BuildContext context,
    List<CollectionWithThumbnail> collections,
    int index,
  ) {
    if (index < collections.length) {
      final c = collections[index];
      return CollectionItem(c);
    } else {
      return InkWell(
        child: Container(
          margin: const EdgeInsets.fromLTRB(30, 30, 30, 54),
          decoration: BoxDecoration(
            color: Theme.of(context).backgroundColor,
            boxShadow: [
              BoxShadow(
                blurRadius: 2,
                spreadRadius: 0,
                offset: const Offset(0, 0),
                color: Theme.of(context).iconTheme.color.withOpacity(0.3),
              )
            ],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.add,
            color: Theme.of(context).iconTheme.color.withOpacity(0.25),
          ),
        ),
        onTap: () async {
          await showToast(
            context,
            "long press to select photos and click + to create an album",
            toastLength: Toast.LENGTH_LONG,
          );
          Bus.instance
              .fire(TabChangedEvent(0, TabChangedEventSource.collectionsPage));
        },
      );
    }
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

class HiddenCollectionsButtonWidget extends StatelessWidget {
  final TextStyle textStyle;

  const HiddenCollectionsButtonWidget(
    this.textStyle, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Theme.of(context).backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(0),
        side: BorderSide(
          width: 0.5,
          color: Theme.of(context).iconTheme.color.withOpacity(0.24),
        ),
      ),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.visibility_off,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const Padding(padding: EdgeInsets.all(6)),
                  FutureBuilder<int>(
                    future: FilesDB.instance.fileCountWithVisibility(
                      kVisibilityArchive,
                      Configuration.instance.getUserID(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data > 0) {
                        return RichText(
                          text: TextSpan(
                            style: textStyle,
                            children: [
                              TextSpan(
                                text: "Hidden",
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              const TextSpan(text: "  \u2022  "),
                              TextSpan(
                                text: snapshot.data.toString(),
                              ),
                              //need to query in db and bring this value
                            ],
                          ),
                        );
                      } else {
                        return RichText(
                          text: TextSpan(
                            style: textStyle,
                            children: [
                              TextSpan(
                                text: "Hidden",
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              //need to query in db and bring this value
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).iconTheme.color,
              ),
            ],
          ),
        ),
      ),
      onPressed: () async {
        routeToPage(
          context,
          ArchivePage(),
        );
      },
    );
  }
}

class DeviceFolderIcon extends StatelessWidget {
  const DeviceFolderIcon(
    this.folder, {
    Key key,
  }) : super(key: key);

  static final kUnsyncedIconOverlay = Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.6),
        ],
        stops: const [0.7, 1],
      ),
    ),
    child: Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Icon(
          Icons.cloud_off_outlined,
          size: 18,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    ),
  );

  final DeviceFolder folder;

  @override
  Widget build(BuildContext context) {
    final isBackedUp =
        Configuration.instance.getPathsToBackUp().contains(folder.path);
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          height: 140,
          width: 120,
          child: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 120,
                  width: 120,
                  child: Hero(
                    tag:
                        "device_folder:" + folder.path + folder.thumbnail.tag(),
                    child: Stack(
                      children: [
                        ThumbnailWidget(
                          folder.thumbnail,
                          shouldShowSyncStatus: false,
                          key: Key(
                            "device_folder:" +
                                folder.path +
                                folder.thumbnail.tag(),
                          ),
                        ),
                        isBackedUp ? Container() : kUnsyncedIconOverlay,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  folder.name,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1
                      .copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        routeToPage(context, DeviceFolderPage(folder));
      },
    );
  }
}

class CollectionItem extends StatelessWidget {
  CollectionItem(
    this.c, {
    Key key,
  }) : super(key: Key(c.collection.id.toString()));

  final CollectionWithThumbnail c;

  @override
  Widget build(BuildContext context) {
    const double horizontalPaddingOfGridRow = 16;
    const double crossAxisSpacingOfGrid = 9;
    Size size = MediaQuery.of(context).size;
    int albumsCountInOneRow = max(size.width ~/ 220.0, 2);
    double totalWhiteSpaceOfRow = (horizontalPaddingOfGridRow * 2) +
        (albumsCountInOneRow - 1) * crossAxisSpacingOfGrid;
    TextStyle albumTitleTextStyle =
        Theme.of(context).textTheme.subtitle1.copyWith(fontSize: 14);
    final double sideOfThumbnail = (size.width / albumsCountInOneRow) -
        (totalWhiteSpaceOfRow / albumsCountInOneRow);
    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: sideOfThumbnail,
              width: sideOfThumbnail,
              child: Hero(
                tag: "collection" + c.thumbnail.tag(),
                child: ThumbnailWidget(
                  c.thumbnail,
                  shouldShowArchiveStatus: c.collection.isArchived(),
                  key: Key(
                    "collection" + c.thumbnail.tag(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: sideOfThumbnail - 40),
                child: Text(
                  c.collection.name,
                  style: albumTitleTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FutureBuilder<int>(
                future: FilesDB.instance.collectionFileCount(c.collection.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data > 0) {
                    return RichText(
                      text: TextSpan(
                        style: albumTitleTextStyle.copyWith(
                          color: albumTitleTextStyle.color.withOpacity(0.5),
                        ),
                        children: [
                          const TextSpan(text: "  \u2022  "),
                          TextSpan(text: snapshot.data.toString()),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        routeToPage(context, CollectionPage(c));
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Alignment alignment;
  final double opacity;

  const SectionTitle(
    this.title, {
    this.opacity = 0.8,
    Key key,
    this.alignment = Alignment.centerLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 0, 0),
      child: Column(
        children: [
          Align(
            alignment: alignment,
            child: Text(
              title,
              style:
                  Theme.of(context).textTheme.headline6.copyWith(fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class EnteSectionTitle extends StatelessWidget {
  final double opacity;

  const EnteSectionTitle({
    this.opacity = 0.8,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 0, 0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "On ",
                    style: Theme.of(context)
                        .textTheme
                        .headline6
                        .copyWith(fontSize: 22),
                  ),
                  TextSpan(
                    text: "ente",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      fontSize: 22,
                      color: Theme.of(context).colorScheme.defaultTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
