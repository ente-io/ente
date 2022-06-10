import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
import 'package:photos/ui/archive_page.dart';
import 'package:photos/ui/collection_page.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/device_folder_page.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/ui/trash_page.dart';
import 'package:photos/utils/local_settings.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';

class CollectionsGalleryWidget extends StatefulWidget {
  const CollectionsGalleryWidget({Key key}) : super(key: key);

  @override
  _CollectionsGalleryWidgetState createState() =>
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
          return loadWidget;
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
    folders.sort((first, second) =>
        second.thumbnail.creationTime.compareTo(first.thumbnail.creationTime));

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
    const double crossAxisSpacingOfGrid = 5;
    final TextStyle trashAndHiddenTextStyle = Theme.of(context)
        .textTheme
        .subtitle1
        .copyWith(
            color:
                Theme.of(context).textTheme.subtitle1.color.withOpacity(0.5));
    Size size = MediaQuery.of(context).size;
    int albumsCountInOneRow = max(size.width ~/ 220.0, 2);
    final double sideOfThumbnail = (size.width / 2) -
        horizontalPaddingOfGridRow -
        ((crossAxisSpacingOfGrid / 2) * (albumsCountInOneRow - 1));
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(6)),
            SectionTitle("On device"),
            Padding(padding: EdgeInsets.all(8)),
            items.folders.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(22),
                    child: nothingToSeeHere(
                        textColor:
                            Theme.of(context).colorScheme.defaultTextColor),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      height: 170,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: items.folders.isEmpty
                            ? nothingToSeeHere(
                                textColor: Theme.of(context)
                                    .colorScheme
                                    .defaultTextColor)
                            : ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.fromLTRB(6, 0, 6, 0),
                                physics: ScrollPhysics(),
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
                SectionTitle("On ente"),
                _sortMenu(),
              ],
            ),
            Padding(padding: EdgeInsets.all(12)),
            Configuration.instance.hasConfiguredAccount()
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: ScrollPhysics(),
                      // to disable GridView's scrolling
                      itemBuilder: (context, index) {
                        return _buildCollection(
                            context, items.collections, index);
                      },
                      itemCount: items.collections.length + 1,
                      // To include the + button
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: albumsCountInOneRow,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: crossAxisSpacingOfGrid,
                          childAspectRatio: sideOfThumbnail /
                              (sideOfThumbnail +
                                  24)), //24 is height of album title
                    ),
                  )
                : nothingToSeeHere(
                    textColor: Theme.of(context).colorScheme.defaultTextColor),
            const SizedBox(height: 10),
            const Divider(),
            const Padding(padding: EdgeInsets.all(8)),
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
                      padding: EdgeInsets.all(0),
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
                                Padding(padding: EdgeInsets.all(6)),
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
                                                    .subtitle1),
                                            TextSpan(text: "  \u2022  "),
                                            TextSpan(
                                                text: snapshot.data.toString()),
                                            //need to query in db and bring this value
                                          ]));
                                    } else {
                                      return RichText(
                                          text: TextSpan(
                                              style: trashAndHiddenTextStyle,
                                              children: [
                                            TextSpan(
                                                text: "Trash",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle1),
                                            //need to query in db and bring this value
                                          ]));
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
                  SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(0),
                      side: BorderSide(
                        width: 0.5,
                        color:
                            Theme.of(context).iconTheme.color.withOpacity(0.24),
                      ),
                    ),
                    child: Container(
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
                                Padding(padding: EdgeInsets.all(6)),
                                FutureBuilder<int>(
                                  future: FilesDB.instance
                                      .fileCountWithVisibility(
                                          kVisibilityArchive,
                                          Configuration.instance.getUserID()),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data > 0) {
                                      return RichText(
                                          text: TextSpan(
                                              style: trashAndHiddenTextStyle,
                                              children: [
                                            TextSpan(
                                                text: "Hidden",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle1),
                                            TextSpan(text: "  \u2022  "),
                                            TextSpan(
                                                text: snapshot.data.toString()),
                                            //need to query in db and bring this value
                                          ]));
                                    } else {
                                      return RichText(
                                          text: TextSpan(
                                              style: trashAndHiddenTextStyle,
                                              children: [
                                            TextSpan(
                                                text: "Hidden",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle1),
                                            //need to query in db and bring this value
                                          ]));
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
                  ),
                ],
              ),
            ),
            Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 36)),
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
      return Text(text,
          style: Theme.of(context).textTheme.subtitle1.copyWith(
              fontSize: 14,
              color: Theme.of(context).iconTheme.color.withOpacity(0.7)));
    }

    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: PopupMenuButton(
        offset: Offset(10, 50),
        initialValue: sortKey?.index ?? 0,
        child: Align(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
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

  Widget _buildCollection(BuildContext context,
      List<CollectionWithThumbnail> collections, int index) {
    if (index < collections.length) {
      final c = collections[index];
      return CollectionItem(c);
    } else {
      return InkWell(
        child: Container(
          margin: EdgeInsets.fromLTRB(30, 30, 30, 54),
          decoration: BoxDecoration(
            color: Theme.of(context).backgroundColor,
            boxShadow: [
              BoxShadow(
                  blurRadius: 2,
                  spreadRadius: 0,
                  offset: Offset(0, 0),
                  color: Theme.of(context).iconTheme.color.withOpacity(0.3))
            ],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.add,
            color: Theme.of(context).iconTheme.color.withOpacity(0.25),
          ),
        ),
        onTap: () async {
          await showToast(context,
              "long press to select photos and click + to create an album",
              toastLength: Toast.LENGTH_LONG);
          Bus.instance
              .fire(TabChangedEvent(0, TabChangedEventSource.collections_page));
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
        child: Container(
          height: 140,
          width: 120,
          // padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  child: Hero(
                    tag:
                        "device_folder:" + folder.path + folder.thumbnail.tag(),
                    child: Stack(
                      children: [
                        ThumbnailWidget(
                          folder.thumbnail,
                          shouldShowSyncStatus: false,
                          key: Key("device_folder:" +
                              folder.path +
                              folder.thumbnail.tag()),
                        ),
                        isBackedUp ? Container() : kUnsyncedIconOverlay,
                      ],
                    ),
                  ),
                  height: 120,
                  width: 120,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  folder.name,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1
                      .copyWith(fontSize: 12, fontFamily: "Inter"),
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
    TextStyle albumTitleTextStyle = Theme.of(context)
        .textTheme
        .subtitle1
        .copyWith(fontSize: 14, fontFamily: "Inter");
    final double sideOfThumbnail =
        (MediaQuery.of(context).size.width / 2) - 18.5;
    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
                child: Hero(
                    tag: "collection" + c.thumbnail.tag(),
                    child: ThumbnailWidget(
                      c.thumbnail,
                      shouldShowArchiveStatus: c.collection.isArchived(),
                      key: Key(
                        "collection" + c.thumbnail.tag(),
                      ),
                    )),
                height: sideOfThumbnail,
                width: sideOfThumbnail),
          ),
          SizedBox(height: 4),
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
                                color:
                                    albumTitleTextStyle.color.withOpacity(0.5)),
                            children: [
                          TextSpan(text: "  \u2022  "),
                          TextSpan(text: snapshot.data.toString()),
                          //need to query in db and bring this value
                        ]));
                  } else {
                    return Container();
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
      margin: EdgeInsets.fromLTRB(24, 12, 0, 0),
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
