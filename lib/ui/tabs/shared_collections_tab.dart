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
import 'package:photos/services/collections_service.dart';
import "package:photos/ui/collections/album/row_item.dart";
import "package:photos/ui/collections/horizontal_grid_view.dart";
import "package:photos/ui/collections/vertical_grid_view.dart";
import 'package:photos/ui/common/loading_widget.dart';
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import 'package:photos/ui/tabs/section_title.dart';
import "package:photos/ui/tabs/shared/empty_state.dart";
import "package:photos/ui/tabs/shared/quick_link_album_item.dart";
import "package:photos/utils/navigation_util.dart";

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
      future: Future.value(_getSharedCollections()),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if ((snapshot.data?.incoming.length ?? 0) == 0 &&
              (snapshot.data?.quickLinks.length ?? 0) == 0 &&
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
    const maxThumbnailWidth = 160.0;
    const double horizontalPaddingOfGridRow = 16;
    const double crossAxisSpacingOfGrid = 9;
    final Size size = MediaQuery.of(context).size;
    final int albumsCountInOneRow = max(size.width ~/ 220.0, 2);
    final double totalWhiteSpaceOfRow = (horizontalPaddingOfGridRow * 2) +
        (albumsCountInOneRow - 1) * crossAxisSpacingOfGrid;
    final double sideOfThumbnail = (size.width / albumsCountInOneRow) -
        (totalWhiteSpaceOfRow / albumsCountInOneRow);
    final bool hasQuickLinks = collections.quickLinks.isNotEmpty;
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            const SizedBox(height: 12),
            SectionTitleRow(
              SectionTitle(title: S.of(context).sharedWithMe),
              trailingWidget: collections.incoming.isNotEmpty
                  ? IconButtonWidget(
                      icon: Icons.chevron_right,
                      iconButtonType: IconButtonType.secondary,
                      onTap: () {
                        unawaited(
                          routeToPage(
                            context,
                            CollectionVerticalGridView(
                              collections.incoming,
                              appTitle: SectionTitle(
                                title: S.of(context).sharedWithMe,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            collections.incoming.isNotEmpty
                ? CollectionsHorizontalGridView(collections.incoming)
                : const IncomingAlbumEmptyState(),
            const SizedBox(height: 16),
            SectionTitleRow(
              SectionTitle(title: S.of(context).sharedByMe),
              trailingWidget: collections.outgoing.isNotEmpty
                  ? IconButtonWidget(
                      icon: Icons.chevron_right,
                      iconButtonType: IconButtonType.secondary,
                      onTap: () {
                        unawaited(
                          routeToPage(
                            context,
                            CollectionVerticalGridView(
                              collections.outgoing,
                              appTitle: SectionTitle(
                                title: S.of(context).sharedByMe,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            collections.outgoing.isNotEmpty
                ? SizedBox(
                    height: maxThumbnailWidth + 48,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: AlbumRowItemWidget(
                            collections.outgoing[index],
                            maxThumbnailWidth,
                            tag: "outgoing",
                          ),
                        );
                      },
                      itemCount: collections.outgoing.length,
                    ),
                  )
                : const OutgoingAlbumEmptyState(),
            if (hasQuickLinks) const SizedBox(height: 12),
            if (hasQuickLinks)
              SectionTitleRow(SectionTitle(title: S.of(context).quickLinks)),
            if (hasQuickLinks) const SizedBox(height: 4),
            if (hasQuickLinks)
              ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return QuickLinkAlbumItem(
                    c: collections.quickLinks[index],
                  );
                },
                itemCount: collections.quickLinks.length,
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  SharedCollections _getSharedCollections() {
    final List<Collection> outgoing = [];
    final List<Collection> incoming = [];
    final List<Collection> quickLinks = [];
    final List<Collection> collections =
        CollectionsService.instance.getCollectionsForUI(includedShared: true);
    for (final c in collections) {
      if (c.owner!.id == Configuration.instance.getUserID()) {
        if (c.hasSharees || c.hasLink && !c.isSharedFilesCollection()) {
          outgoing.add(c);
        } else if (c.isSharedFilesCollection()) {
          quickLinks.add(c);
        }
      } else {
        incoming.add(c);
      }
    }
    incoming.sort((first, second) {
      return second.updationTime.compareTo(first.updationTime);
    });
    return SharedCollections(outgoing, incoming, quickLinks);
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
