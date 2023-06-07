import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/user_logged_out_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import "package:photos/models/file.dart";
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/tabs/section_title.dart';
import "package:photos/ui/tabs/shared/empty_state.dart";
import "package:photos/ui/tabs/shared/incoming_album_item.dart";
import "package:photos/ui/tabs/shared/outgoing_album_item.dart";

class SharedCollectionsTab extends StatefulWidget {
  const SharedCollectionsTab({Key? key}) : super(key: key);

  @override
  State<SharedCollectionsTab> createState() => _SharedCollectionsTabState();
}

class _SharedCollectionsTabState extends State<SharedCollectionsTab>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger("SharedCollectionGallery");
  late StreamSubscription<LocalPhotosUpdatedEvent> _localFilesSubscription;
  late StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;
  late StreamSubscription<UserLoggedOutEvent> _loggedOutEvent;

  @override
  void initState() {
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      debugPrint("SetState Shared Collections on ${event.reason}");
      setState(() {});
    });
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      debugPrint("SetState Shared Collections on ${event.reason}");
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
        return _getSharedCollections(files);
      }),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if ((snapshot.data?.incoming.length ?? 0) == 0 &&
              (snapshot.data?.outgoing.length ?? 0) == 0) {
            return const Center(child: SharedEmptyStateWidget());
          }
          return _getSharedCollectionsGallery(snapshot.data!);
        } else if (snapshot.hasError) {
          _logger.severe(
            "critical: failed to load share gallery",
            snapshot.error,
            snapshot.stackTrace,
          );
          return Center(child: Text(S.of(context).somethingWentWrong));
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }

  Widget _getSharedCollectionsGallery(SharedCollections collections) {
    const double horizontalPaddingOfGridRow = 16;
    const double crossAxisSpacingOfGrid = 9;
    final Size size = MediaQuery.of(context).size;
    final int albumsCountInOneRow = max(size.width ~/ 220.0, 2);
    final double totalWhiteSpaceOfRow = (horizontalPaddingOfGridRow * 2) +
        (albumsCountInOneRow - 1) * crossAxisSpacingOfGrid;
    final double sideOfThumbnail = (size.width / albumsCountInOneRow) -
        (totalWhiteSpaceOfRow / albumsCountInOneRow);
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            const SizedBox(height: 12),
            SectionTitle(title: S.of(context).sharedWithMe),
            const SizedBox(height: 12),
            collections.incoming.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return IncomingAlbumItem(
                          collections.incoming[index],
                        );
                      },
                      itemCount: collections.incoming.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: albumsCountInOneRow,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: crossAxisSpacingOfGrid,
                        childAspectRatio:
                            sideOfThumbnail / (sideOfThumbnail + 24),
                      ), //24 is height of album title
                    ),
                  )
                : const IncomingAlbumEmptyState(),
            const SizedBox(height: 16),
            SectionTitle(title: S.of(context).sharedByMe),
            const SizedBox(height: 12),
            collections.outgoing.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 12),
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return OutgoingAlbumItem(
                        c: collections.outgoing[index],
                      );
                    },
                    itemCount: collections.outgoing.length,
                  )
                : const OutgoingAlbumEmptyState(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  SharedCollections _getSharedCollections(List<File> recentFileForCollections) {
    final List<CollectionWithThumbnail> outgoing = [];
    final List<CollectionWithThumbnail> incoming = [];
    for (final file in recentFileForCollections) {
      if (file.collectionID == null) {
        _logger.severe("collection id should not be null");
        continue;
      }
      final Collection? c =
          CollectionsService.instance.getCollectionByID(file.collectionID!);
      if (c == null) {
        _logger.severe("shared collection is not cached ${file.collectionID}");
        CollectionsService.instance
            .fetchCollectionByID(file.collectionID!)
            .ignore();
        continue;
      }
      if (c.owner!.id == Configuration.instance.getUserID()) {
        if (c.hasSharees || c.hasLink || c.isSharedFilesCollection()) {
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
      if (second.collection.isSharedFilesCollection() ==
          first.collection.isSharedFilesCollection()) {
        return second.collection.updationTime
            .compareTo(first.collection.updationTime);
      } else {
        if (first.collection.isSharedFilesCollection()) {
          return 1;
        }
        return -1;
      }
    });
    incoming.sort((first, second) {
      return second.collection.updationTime
          .compareTo(first.collection.updationTime);
    });
    return SharedCollections(outgoing, incoming);
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
