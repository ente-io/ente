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
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/favorites_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/button/archived_button.dart";
import "package:photos/ui/collections/button/hidden_button.dart";
import "package:photos/ui/collections/button/trash_button.dart";
import "package:photos/ui/collections/button/uncategorized_button.dart";
import "package:photos/ui/collections/create_new_album_widget.dart";
import "package:photos/ui/collections/device/device_folders_grid_view.dart";
import "package:photos/ui/collections/device/device_folders_vertical_grid_view.dart";
import 'package:photos/ui/collections/horizontal_grid_view.dart';
import "package:photos/ui/collections/vertical_grid_view.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/tabs/section_title.dart';
import 'package:photos/ui/viewer/actions/delete_empty_albums.dart';
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import 'package:photos/utils/local_settings.dart';
import "package:photos/utils/navigation_util.dart";

class UserCollectionsTab extends StatefulWidget {
  const UserCollectionsTab({Key? key}) : super(key: key);

  @override
  State<UserCollectionsTab> createState() => _UserCollectionsTabState();
}

class _UserCollectionsTabState extends State<UserCollectionsTab>
    with AutomaticKeepAliveClientMixin {
  final _logger = Logger((_UserCollectionsTabState).toString());
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
    return FutureBuilder<List<Collection>>(
      future: _getCollections(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _getCollectionsGalleryWidget(snapshot.data!);
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }

  Future<List<Collection>> _getCollections() async {
    final List<Collection> collections =
        CollectionsService.instance.getCollectionsForUI();
    final bool hasFavorites = FavoritesService.instance.hasFavorites();
    late Map<int, int> collectionIDToNewestPhotoTime;
    if (sortKey == AlbumSortKey.newestPhoto) {
      collectionIDToNewestPhotoTime =
          await CollectionsService.instance.getCollectionIDToNewestFileTime();
    }
    collections.sort(
      (first, second) {
        if (sortKey == AlbumSortKey.albumName) {
          return compareAsciiLowerCaseNatural(
            first.displayName,
            second.displayName,
          );
        } else if (sortKey == AlbumSortKey.newestPhoto) {
          return (collectionIDToNewestPhotoTime[second.id] ?? -1 * intMaxValue)
              .compareTo(
            collectionIDToNewestPhotoTime[first.id] ?? -1 * intMaxValue,
          );
        } else {
          return second.updationTime.compareTo(first.updationTime);
        }
      },
    );
    final List<Collection> favorites = [];
    final List<Collection> pinned = [];
    final List<Collection> rest = [];
    for (final collection in collections) {
      if (collection.type == CollectionType.uncategorized ||
          collection.isSharedFilesCollection() ||
          collection.isHidden()) {
        continue;
      }
      if (collection.type == CollectionType.favorites) {
        // Hide fav collection if it's empty
        if (hasFavorites) {
          favorites.add(collection);
        }
      } else if (collection.isPinned) {
        pinned.add(collection);
      } else {
        rest.add(collection);
      }
    }

    return favorites + pinned + rest;
  }

  Widget _getCollectionsGalleryWidget(List<Collection> collections) {
    final TextStyle trashAndHiddenTextStyle =
        Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .color!
                  .withOpacity(0.5),
            );
    final enteTextTheme = getEnteTextTheme(context);

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            SectionOptions(
              SectionTitle(title: S.of(context).onDevice),
              trailingWidget: IconButtonWidget(
                icon: Icons.chevron_right,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  unawaited(
                    routeToPage(
                      context,
                      DeviceFolderVerticalGridView(
                        appTitle: SectionTitle(
                          title: S.of(context).onDevice,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const DeviceFoldersGridView(),
            SectionOptions(
              SectionTitle(titleWithBrand: getOnEnteSection(context)),
              trailingWidget: _sortMenu(collections),
              padding: const EdgeInsets.only(left: 12, right: 6),
            ),
            DeleteEmptyAlbums(collections ?? []),
            Configuration.instance.hasConfiguredAccount()
                ? CollectionsHorizontalGridView(collections)
                : const EmptyState(),
            collections.length > 4
                ? GestureDetector(
                    onTap: () {
                      unawaited(
                        routeToPage(
                          context,
                          CollectionVerticalGridView(
                            collections,
                            appTitle: SectionTitle(
                              titleWithBrand: getOnEnteSection(context),
                            ),
                          ),
                        ),
                      );
                    },
                    child: SectionOptions(
                      SectionTitle(
                          title: S.of(context).viewAll, mutedTitle: true),
                      trailingWidget: const IconButtonWidget(
                        icon: Icons.chevron_right,
                        iconButtonType: IconButtonType.secondary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            const Divider(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  UnCategorizedCollections(trashAndHiddenTextStyle),
                  const SizedBox(height: 12),
                  ArchivedCollectionsButton(trashAndHiddenTextStyle),
                  const SizedBox(height: 12),
                  HiddenCollectionsButtonWidget(trashAndHiddenTextStyle),
                  const SizedBox(height: 12),
                  TrashSectionButton(trashAndHiddenTextStyle),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _sortMenu(List<Collection> collections) {
    Text sortOptionText(AlbumSortKey key) {
      String text = key.toString();
      switch (key) {
        case AlbumSortKey.albumName:
          text = S.of(context).name;
          break;
        case AlbumSortKey.newestPhoto:
          text = S.of(context).newest;
          break;
        case AlbumSortKey.lastUpdated:
          text = S.of(context).lastUpdated;
      }
      return Text(
        text,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: 14,
              color: Theme.of(context).iconTheme.color!.withOpacity(0.7),
            ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: Row(
        children: [
          const CreateNewAlbumIcon(),
          GestureDetector(
            onTapDown: (TapDownDetails details) async {
              final int? selectedValue = await showMenu<int>(
                context: context,
                position: RelativeRect.fromLTRB(
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                  details.globalPosition.dx,
                  details.globalPosition.dy + 50,
                ),
                items: List.generate(AlbumSortKey.values.length, (index) {
                  return PopupMenuItem(
                    value: index,
                    child: sortOptionText(AlbumSortKey.values[index]),
                  );
                }),
              );
              if (selectedValue != null) {
                sortKey = AlbumSortKey.values[selectedValue];
                ;
                await LocalSettings.instance.setAlbumSortKey(sortKey!);
                setState(() {});
              }
            },
            child: const IconButtonWidget(
              icon: Icons.sort_outlined,
              iconButtonType: IconButtonType.secondary,
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
