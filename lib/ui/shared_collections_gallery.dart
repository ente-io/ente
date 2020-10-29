import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/collections_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/remote_sync_event.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/shared_collection_page.dart';
import 'package:photos/ui/thumbnail_widget.dart';

class SharedCollectionGallery extends StatefulWidget {
  const SharedCollectionGallery({Key key}) : super(key: key);

  @override
  _SharedCollectionGalleryState createState() =>
      _SharedCollectionGalleryState();
}

class _SharedCollectionGalleryState extends State<SharedCollectionGallery> {
  Logger _logger = Logger("SharedCollectionGallery");
  StreamSubscription<RemoteSyncEvent> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<RemoteSyncEvent>().listen((event) {
      if (event.success) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CollectionWithThumbnail>>(
      future:
          CollectionsDB.instance.getAllCollections().then((collections) async {
        final c = List<CollectionWithThumbnail>();
        for (final collection in collections) {
          if (collection.ownerID == Configuration.instance.getUserID()) {
            continue;
          }
          final thumbnail =
              await FilesDB.instance.getLatestFileInCollection(collection.id);
          if (thumbnail == null) {
            continue;
          }
          final lastUpdatedFile = await FilesDB.instance
              .getLastModifiedFileInCollection(collection.id);
          c.add(CollectionWithThumbnail(
            collection,
            thumbnail,
            lastUpdatedFile,
          ));
        }
        c.sort((first, second) {
          return second.lastUpdatedFile.updationTime
              .compareTo(first.lastUpdatedFile.updationTime);
        });
        return c;
      }),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isEmpty) {
            return nothingToSeeHere;
          } else {
            return _getSharedCollectionsGallery(snapshot.data);
          }
        } else if (snapshot.hasError) {
          _logger.shout(snapshot.error);
          return Center(child: Text(snapshot.error.toString()));
        } else {
          return loadWidget;
        }
      },
    );
  }

  Widget _getSharedCollectionsGallery(
      List<CollectionWithThumbnail> collections) {
    return Container(
      margin: EdgeInsets.only(top: 24),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.only(bottom: 12),
        physics: ScrollPhysics(), // to disable GridView's scrolling
        itemBuilder: (context, index) {
          return _buildCollection(context, collections[index]);
        },
        itemCount: collections.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      ),
    );
  }

  Widget _buildCollection(BuildContext context, CollectionWithThumbnail c) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Container(
              child: c.thumbnail ==
                      null // When the user has shared a folder without photos
                  ? Icon(Icons.error)
                  : Hero(
                      tag: "shared_collection" + c.thumbnail.tag(),
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
        final page = SharedCollectionPage(c.collection);
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
