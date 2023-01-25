import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/user_logged_out_event.dart';
import 'package:photos/extensions/list.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/collections/archived_collections_button_widget.dart';
import 'package:photos/ui/collections/device_folders_grid_view_widget.dart';
import 'package:photos/ui/collections/hidden_collections_button_widget.dart';
import 'package:photos/ui/collections/remote_collections_grid_view_widget.dart';
import 'package:photos/ui/collections/section_title.dart';
import 'package:photos/ui/collections/trash_button_widget.dart';
import 'package:photos/ui/collections/uncat_collections_button_widget.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/actions/delete_empty_albums.dart';
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import 'package:photos/utils/local_settings.dart';

class CollectionsGalleryWidget extends StatefulWidget {
  const CollectionsGalleryWidget({Key? key}) : super(key: key);

  @override
  State<CollectionsGalleryWidget> createState() =>
      _CollectionsGalleryWidgetState();
}

class _CollectionsGalleryWidgetState extends State<CollectionsGalleryWidget>
    with AutomaticKeepAliveClientMixin {
  final _logger = Logger((_CollectionsGalleryWidgetState).toString());
  late StreamSubscription<LocalPhotosUpdatedEvent> _localFilesSubscription;
  late StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;
  late StreamSubscription<UserLoggedOutEvent> _loggedOutEvent;
  AlbumSortKey? sortKey;
  String _loadReason = "init";

  @override
  void initState() {
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _loadReason = event.reason;
      setState(() {});
    });
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      _loadReason = event.reason;
      setState(() {});
    });
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((event) {
      _loadReason = event.reason;
      setState(() {});
    });
    sortKey = LocalSettings.instance.albumSortKey();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _logger.info("Building, trigger: $_loadReason");
    return FutureBuilder<List<CollectionWithThumbnail>>(
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

  Future<List<CollectionWithThumbnail>> _getCollections() async {
    final List<CollectionWithThumbnail> collectionsWithThumbnail =
        await CollectionsService.instance.getCollectionsWithThumbnails();

    // Remove uncategorized collection
    collectionsWithThumbnail
        .removeWhere((t) => t.collection.type == CollectionType.uncategorized);
    final ListMatch<CollectionWithThumbnail> favMathResult =
        collectionsWithThumbnail.splitMatch(
      (element) => element.collection.type == CollectionType.favorites,
    );

    // Hide fav collection if it's empty and not shared
    favMathResult.matched.removeWhere(
      (element) =>
          element.thumbnail == null &&
          (element.collection.publicURLs?.isEmpty ?? false),
    );

    favMathResult.unmatched.sort(
      (first, second) {
        if (sortKey == AlbumSortKey.albumName) {
          return compareAsciiLowerCaseNatural(
            first.collection.name!,
            second.collection.name!,
          );
        } else if (sortKey == AlbumSortKey.newestPhoto) {
          return (second.thumbnail?.creationTime ?? -1 * intMaxValue)
              .compareTo(first.thumbnail?.creationTime ?? -1 * intMaxValue);
        } else {
          return second.collection.updationTime
              .compareTo(first.collection.updationTime);
        }
      },
    );
    // This is a way to identify collection which were automatically created
    // during create link flow for selected files
    final ListMatch<CollectionWithThumbnail> potentialSharedLinkCollection =
        favMathResult.unmatched.splitMatch(
      (e) => (e.collection.isSharedFilesCollection()),
    );

    return favMathResult.matched + potentialSharedLinkCollection.unmatched;
  }

  Widget _getCollectionsGalleryWidget(
    List<CollectionWithThumbnail>? collections,
  ) {
    final bool showDeleteAlbumsButton =
        collections!.where((c) => c.thumbnail == null).length >= 3;
    final TextStyle trashAndHiddenTextStyle = Theme.of(context)
        .textTheme
        .subtitle1!
        .copyWith(
          color: Theme.of(context).textTheme.subtitle1!.color!.withOpacity(0.5),
        );

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const SectionTitle(title: "On device"),
            const SizedBox(height: 12),
            const DeviceFoldersGridViewWidget(),
            const Padding(padding: EdgeInsets.all(4)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SectionTitle(titleWithBrand: getOnEnteSection(context)),
                _sortMenu(),
              ],
            ),
            showDeleteAlbumsButton
                ? const Padding(
                    padding: EdgeInsets.only(top: 2, left: 8.5, right: 48),
                    child: DeleteEmptyAlbums(),
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 12),
            Configuration.instance.hasConfiguredAccount()
                ? RemoteCollectionsGridViewWidget(collections)
                : const EmptyState(),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  UnCatCollectionsButtonWidget(trashAndHiddenTextStyle),
                  const SizedBox(height: 12),
                  ArchivedCollectionsButtonWidget(trashAndHiddenTextStyle),
                  const SizedBox(height: 12),
                  HiddenCollectionsButtonWidget(trashAndHiddenTextStyle),
                  const SizedBox(height: 12),
                  TrashButtonWidget(trashAndHiddenTextStyle),
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
        style: Theme.of(context).textTheme.subtitle1!.copyWith(
              fontSize: 14,
              color: Theme.of(context).iconTheme.color!.withOpacity(0.7),
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
          await LocalSettings.instance.setAlbumSortKey(sortKey!);
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
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
