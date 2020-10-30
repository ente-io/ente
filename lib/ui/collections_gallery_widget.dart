import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/repositories/file_repository.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/ui/collection_page.dart';
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

class _CollectionsGalleryWidgetState extends State<CollectionsGalleryWidget> {
  final _logger = Logger("CollectionsGallery");
  StreamSubscription<LocalPhotosUpdatedEvent> _localFilesSubscription;
  StreamSubscription<CollectionUpdatedEvent> _collectionUpdatesSubscription;

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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _getCollectionsGalleryWidget(CollectionItems items) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SectionTitle("Device Folders"),
          Container(
            height: 160,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                physics: ScrollPhysics(), // to disable GridView's scrolling
                itemBuilder: (context, index) {
                  return _buildFolder(context, items.folders[index]);
                },
                itemCount: items.folders.length,
              ),
            ),
          ),
          Divider(height: 12),
          SectionTitle("Collections"),
          Padding(padding: EdgeInsets.all(6)),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: 12),
            physics: ScrollPhysics(), // to disable GridView's scrolling
            itemBuilder: (context, index) {
              return _buildCollection(context, items.collections, index);
            },
            itemCount: items.collections.length + 1, // To include the + button
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
          ),
        ],
      ),
    );
  }

  Future<CollectionItems> _getCollections() async {
    final userID = Configuration.instance.getUserID();
    final paths = await FilesDB.instance.getLocalPaths();
    final folders = List<DeviceFolder>();
    for (final path in paths) {
      final files = List<File>();
      for (File file in FileRepository.instance.files) {
        if ((file.ownerID == null || file.ownerID == userID) &&
            file.deviceFolder == path) {
          files.add(file);
        }
      }
      final folderName = p.basename(path);
      folders.add(DeviceFolder(folderName, path, () => files, files[0]));
    }
    folders.sort((first, second) {
      return second.thumbnail.creationTime
          .compareTo(first.thumbnail.creationTime);
    });

    final collectionsWithThumbnail = List<CollectionWithThumbnail>();
    final collections = CollectionsService.instance.getCollections();

    for (final c in collections) {
      if (c.ownerID != userID) {
        continue;
      }
      final thumbnail = await FilesDB.instance.getLatestFileInCollection(c.id);
      if (thumbnail == null) {
        continue;
      }
      final lastUpdatedFile =
          await FilesDB.instance.getLastModifiedFileInCollection(c.id);
      collectionsWithThumbnail.add(CollectionWithThumbnail(
        c,
        thumbnail,
        lastUpdatedFile,
      ));
    }
    collectionsWithThumbnail.sort((first, second) {
      return second.lastUpdatedFile.updationTime
          .compareTo(first.lastUpdatedFile.updationTime);
    });

    return CollectionItems(folders, collectionsWithThumbnail);
  }

  Widget _buildFolder(BuildContext context, DeviceFolder folder) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Container(
                child: Hero(
                    tag:
                        "device_folder:" + folder.path + folder.thumbnail.tag(),
                    child: ThumbnailWidget(folder.thumbnail)),
                height: 110,
                width: 110,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                folder.name,
                style: TextStyle(
                  fontSize: 14,
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
    if (index == collections.length) {
      return Container(
        padding: EdgeInsets.fromLTRB(28, 0, 28, 56),
        child: OutlineButton(
          child: Icon(
            Icons.add,
          ),
          onPressed: () async {
            await showToast(
                "Long press to select photos and click + to create an album.",
                toastLength: Toast.LENGTH_LONG);
            Bus.instance.fire(TabChangedEvent(0));
          },
        ),
      );
    }
    final c = collections[index];
    return GestureDetector(
      child: Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Container(
              child: Hero(
                  tag: "collection" + c.thumbnail.tag(),
                  child: ThumbnailWidget(c.thumbnail)),
              height: 150,
              width: 150,
            ),
          ),
          Padding(padding: EdgeInsets.all(2)),
          Expanded(
            child: Text(
              c.collection.name,
              style: TextStyle(
                fontSize: 16,
              ),
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
  }

  @override
  void dispose() {
    _localFilesSubscription.cancel();
    _collectionUpdatesSubscription.cancel();
    super.dispose();
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.fromLTRB(12, 12, 0, 0),
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorLight,
              ),
            ),
          ),
        ]));
  }
}
