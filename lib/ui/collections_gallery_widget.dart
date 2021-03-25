import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/events/user_logged_out_event.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/ui/collection_page.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/device_folder_page.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:path/path.dart' as p;
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

  @override
  void initState() {
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      setState(() {});
    });
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      setState(() {});
    });
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((event) {
      setState(() {});
    });
    _backupFoldersUpdatedEvent =
        Bus.instance.on<BackupFoldersUpdatedEvent>().listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
    final folders = List<DeviceFolder>();
    final paths = await filesDB.getLocalPaths();
    for (final path in paths) {
      final folderName = p.basename(path);
      folders.add(DeviceFolder(
          folderName, path, await filesDB.getLastCreatedFileInPath(path)));
    }
    folders.sort((first, second) =>
        second.thumbnail.creationTime.compareTo(first.thumbnail.creationTime));
    final collectionsWithThumbnail = List<CollectionWithThumbnail>();
    final collections = collectionsService.getCollections();
    for (final c in collections) {
      if (c.owner.id == userID) {
        final thumbnail =
            await FilesDB.instance.getLatestFileInCollection(c.id);
        if (thumbnail == null) {
          continue;
        }
        collectionsWithThumbnail
            .add(CollectionWithThumbnail(c, thumbnail, null));
      }
    }
    collectionsWithThumbnail.sort((first, second) {
      return second.thumbnail.updationTime
          .compareTo(first.thumbnail.updationTime);
    });

    return CollectionItems(folders, collectionsWithThumbnail);
  }

  Widget _getCollectionsGalleryWidget(CollectionItems items) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(6)),
            SectionTitle("device folders"),
            Padding(padding: EdgeInsets.all(6)),
            items.folders.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(22),
                    child: nothingToSeeHere,
                  )
                : Container(
                    height: 160,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: items.folders.isEmpty
                          ? nothingToSeeHere
                          : ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
                              physics:
                                  ScrollPhysics(), // to disable GridView's scrolling
                              itemBuilder: (context, index) {
                                return _buildFolder(
                                    context, items.folders[index]);
                              },
                              itemCount: items.folders.length,
                            ),
                    ),
                  ),
            Divider(),
            Padding(padding: EdgeInsets.all(10)),
            SectionTitle("backed-up memories"),
            Padding(padding: EdgeInsets.all(14)),
            BillingService.instance.hasActiveSubscription()
                ? GridView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
                    physics: ScrollPhysics(), // to disable GridView's scrolling
                    itemBuilder: (context, index) {
                      return _buildCollection(
                          context, items.collections, index);
                    },
                    itemCount:
                        items.collections.length + 1, // To include the + button
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                    ),
                  )
                : nothingToSeeHere,
          ],
        ),
      ),
    );
  }

  Widget _buildFolder(BuildContext context, DeviceFolder folder) {
    final isBackedUp =
        Configuration.instance.getPathsToBackUp().contains(folder.path);
    return GestureDetector(
      child: Container(
        height: 110,
        width: 132,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(18.0),
              child: Container(
                child: Hero(
                  tag: "device_folder:" + folder.path + folder.thumbnail.tag(),
                  child: Stack(
                    children: [
                      ThumbnailWidget(
                        folder.thumbnail,
                        shouldShowSyncStatus: false,
                      ),
                      isBackedUp
                          ? Container()
                          : Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(right: 8, bottom: 6),
                                child: Icon(
                                  Icons.cloud_off_outlined,
                                  size: 18,
                                ),
                              ),
                            )
                    ],
                  ),
                ),
                height: 110,
                width: 110,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                folder.name,
                style: TextStyle(
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return DeviceFolderPage(folder);
            },
          ),
        );
      },
    );
  }

  Widget _buildCollection(BuildContext context,
      List<CollectionWithThumbnail> collections, int index) {
    if (index < collections.length) {
      final c = collections[index];
      return GestureDetector(
        child: Column(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(18.0),
              child: Container(
                child: Hero(
                    tag: "collection" + c.thumbnail.tag(),
                    child: ThumbnailWidget(c.thumbnail)),
                height: 140,
                width: 140,
              ),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Expanded(
              child: Text(
                c.collection.name,
                style: TextStyle(
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        onTap: () {
          final page = CollectionPage(c.collection);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return page;
              },
            ),
          );
        },
      );
    } else {
      return Container(
        padding: EdgeInsets.fromLTRB(28, 12, 28, 46),
        child: OutlineButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          child: Icon(
            Icons.add,
          ),
          onPressed: () async {
            await showToast(
                "long press to select photos and click + to create an album",
                toastLength: Toast.LENGTH_LONG);
            Bus.instance.fire(
                TabChangedEvent(0, TabChangedEventSource.collections_page));
          },
        ),
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

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.fromLTRB(24, 12, 0, 0),
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).buttonColor.withOpacity(0.8),
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
          ),
        ]));
  }
}
