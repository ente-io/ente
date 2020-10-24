import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/repositories/file_repository.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/ui/collection_page.dart';
import 'package:photos/ui/device_folder_page.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:path/path.dart' as p;

class CollectionsGalleryWidget extends StatefulWidget {
  const CollectionsGalleryWidget({Key key}) : super(key: key);

  @override
  _CollectionsGalleryWidgetState createState() =>
      _CollectionsGalleryWidgetState();
}

class _CollectionsGalleryWidgetState extends State<CollectionsGalleryWidget> {
  StreamSubscription<LocalPhotosUpdatedEvent> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
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
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
              physics: ScrollPhysics(), // to disable GridView's scrolling
              itemBuilder: (context, index) {
                return _buildFolder(context, items.folders[index]);
              },
              itemCount: items.folders.length,
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
              return _buildCollection(context, items.collections[index]);
            },
            itemCount: items.collections.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
          ),
        ],
      ),
    );
  }

  Future<CollectionItems> _getCollections() async {
    final paths = await FilesDB.instance.getLocalPaths();
    final folders = List<DeviceFolder>();
    for (final path in paths) {
      final files = List<File>();
      for (File file in FileRepository.instance.files) {
        if (file.deviceFolder == path) {
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

    final collections = List<CollectionWithThumbnail>();
    final favorites = FavoritesService.instance.getFavoriteFiles().toList();
    favorites.sort((first, second) {
      return second.creationTime.compareTo(first.creationTime);
    });
    if (favorites.length > 0) {
      collections.add(CollectionWithThumbnail(
          FavoritesService.instance.getFavoritesCollection(), favorites[0]));
    }
    return CollectionItems(folders, collections);
  }

  Widget _buildFolder(BuildContext context, DeviceFolder folder) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Container(
              child: Hero(
                  tag: "device_folder:" + folder.path + folder.thumbnail.tag(),
                  child: ThumbnailWidget(folder.thumbnail)),
              height: 110,
              width: 110,
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

  Widget _buildCollection(BuildContext context, CollectionWithThumbnail c) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Container(
            child: c.thumbnail ==
                    null // When the user has shared a folder without photos
                ? Icon(Icons.error)
                : Hero(
                    tag: "collection" + c.thumbnail.tag(),
                    child: ThumbnailWidget(c.thumbnail)),
            height: 150,
            width: 150,
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
    _subscription.cancel();
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

class CollectionItems {
  final List<DeviceFolder> folders;
  final List<CollectionWithThumbnail> collections;

  CollectionItems(this.folders, this.collections);
}

class CollectionWithThumbnail {
  final Collection collection;
  final File thumbnail;

  CollectionWithThumbnail(this.collection, this.thumbnail);
}
