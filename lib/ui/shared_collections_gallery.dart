import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/events/user_logged_out_event.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/collection_page.dart';
import 'package:photos/ui/collections_gallery_widget.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

class SharedCollectionGallery extends StatefulWidget {
  const SharedCollectionGallery({Key key}) : super(key: key);

  @override
  _SharedCollectionGalleryState createState() =>
      _SharedCollectionGalleryState();
}

class _SharedCollectionGalleryState extends State<SharedCollectionGallery>
    with AutomaticKeepAliveClientMixin {
  Logger _logger = Logger("SharedCollectionGallery");
  StreamSubscription<LocalPhotosUpdatedEvent> _localFilesSubscription;
  StreamSubscription<CollectionUpdatedEvent> _collectionUpdatesSubscription;
  StreamSubscription<UserLoggedOutEvent> _loggedOutEvent;

  @override
  void initState() {
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _logger.info("Files updated");
      setState(() {});
    });
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      setState(() {});
    });
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<SharedCollections>(
      future:
          Future.value(CollectionsService.instance.getLatestCollectionFiles())
              .then((files) async {
        final List<CollectionWithThumbnail> outgoing = [];
        final List<CollectionWithThumbnail> incoming = [];
        for (final file in files) {
          final c =
              CollectionsService.instance.getCollectionByID(file.collectionID);
          if (c.owner.id == Configuration.instance.getUserID()) {
            if (c.sharees.isNotEmpty) {
              outgoing.add(
                CollectionWithThumbnail(
                  c,
                  file,
                ),
              );
            }
          } else {
            incoming.add(
              CollectionWithThumbnail(
                c,
                file,
              ),
            );
          }
        }
        outgoing.sort((first, second) {
          return second.collection.updationTime
              .compareTo(first.collection.updationTime);
        });
        incoming.sort((first, second) {
          return second.collection.updationTime
              .compareTo(first.collection.updationTime);
        });
        return SharedCollections(outgoing, incoming);
      }),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _getSharedCollectionsGallery(snapshot.data);
        } else if (snapshot.hasError) {
          _logger.shout(snapshot.error);
          return Center(child: Text(snapshot.error.toString()));
        } else {
          return loadWidget;
        }
      },
    );
  }

  Widget _getSharedCollectionsGallery(SharedCollections collections) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(6)),
            SectionTitle("incoming"),
            Padding(padding: EdgeInsets.all(16)),
            collections.incoming.isNotEmpty
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return IncomingCollectionItem(
                          collections.incoming[index]);
                    },
                    itemCount: collections.incoming.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                  )
                : _getIncomingCollectionEmptyState(),
            Padding(padding: EdgeInsets.all(16)),
            Divider(height: 0),
            Padding(padding: EdgeInsets.all(14)),
            SectionTitle("outgoing"),
            Padding(padding: EdgeInsets.all(16)),
            collections.outgoing.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: 12),
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return OutgoingCollectionItem(
                            collections.outgoing[index]);
                      },
                      itemCount: collections.outgoing.length,
                    ),
                  )
                : _getOutgoingCollectionEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _getIncomingCollectionEmptyState() {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Text(
            "no one is sharing with you",
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(28, 20, 28, 46),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.fromLTRB(50, 16, 50, 16),
                side: BorderSide(
                  width: 2,
                  color: Theme.of(context).buttonColor.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.outgoing_mail,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  Padding(padding: EdgeInsets.all(6)),
                  Text(
                    "invite",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              onPressed: () async {
                shareText("Check out https://ente.io");
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getOutgoingCollectionEmptyState() {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Text(
            "you aren't sharing anything",
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(28, 20, 28, 46),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.fromLTRB(50, 16, 50, 16),
                side: BorderSide(
                  width: 2,
                  color: Theme.of(context).buttonColor.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  Padding(padding: EdgeInsets.all(6)),
                  Text(
                    "share",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              onPressed: () async {
                await showToast("select an album on ente to share",
                    toastLength: Toast.LENGTH_LONG);
                Bus.instance.fire(
                    TabChangedEvent(1, TabChangedEventSource.collections_page));
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _localFilesSubscription.cancel();
    _collectionUpdatesSubscription.cancel();
    _loggedOutEvent.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

class OutgoingCollectionItem extends StatelessWidget {
  final CollectionWithThumbnail c;

  const OutgoingCollectionItem(
    this.c, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sharees = <String>[];
    for (int index = 0; index < c.collection.sharees.length; index++) {
      if (index < 2) {
        sharees.add(c.collection.sharees[index].name);
      } else {
        final remaining = c.collection.sharees.length - index;
        if (remaining == 1) {
          // If it's the last sharee
          sharees.add(c.collection.sharees[index].name);
        } else {
          sharees.add("and " +
              remaining.toString() +
              " other" +
              (remaining > 1 ? "s" : ""));
        }
        break;
      }
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                child: Hero(
                    tag: "outgoing_collection" + c.thumbnail.tag(),
                    child: ThumbnailWidget(
                      c.thumbnail,
                      key: Key("outgoing_collection" + c.thumbnail.tag()),
                    )),
                height: 60,
                width: 60,
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.collection.name,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
                  child: Text(
                    "Shared with " + sharees.join(", "),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColorLight,
                    ),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      onTap: () {
        final page = CollectionPage(
          c,
          appBarType: GalleryAppBarType.owned_collection,
          tagPrefix: "outgoing_collection",
        );
        routeToPage(context, page);
      },
    );
  }
}

class IncomingCollectionItem extends StatelessWidget {
  final CollectionWithThumbnail c;

  const IncomingCollectionItem(
    this.c, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(18.0),
            child: Container(
              child: Stack(
                children: [
                  Hero(
                      tag: "shared_collection" + c.thumbnail.tag(),
                      child: ThumbnailWidget(
                        c.thumbnail,
                        key: Key("shared_collection" + c.thumbnail.tag()),
                      )),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      child: Text(
                        c.collection.owner.name == null ||
                                c.collection.owner.name.isEmpty
                            ? c.collection.owner.email.substring(0, 1)
                            : c.collection.owner.name.substring(0, 1),
                        textAlign: TextAlign.center,
                      ),
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.fromLTRB(0, 0, 4, 0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).buttonColor,
                      ),
                    ),
                  ),
                ],
              ),
              height: 160,
              width: 160,
            ),
          ),
          Padding(padding: EdgeInsets.all(2)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Text(
                c.collection.name,
                style: TextStyle(
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        routeToPage(
            context,
            CollectionPage(c,
                appBarType: GalleryAppBarType.shared_collection,
                tagPrefix: "shared_collection"));
      },
    );
  }
}
