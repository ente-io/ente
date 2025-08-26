import 'dart:async';
import "dart:math";

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import 'package:photos/core/event_bus.dart';
import "package:photos/events/album_sort_order_change_event.dart";
import 'package:photos/events/collection_updated_event.dart';
import "package:photos/events/favorites_service_init_complete_event.dart";
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/events/tab_changed_event.dart";
import 'package:photos/events/user_logged_out_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/selected_albums.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/album/row_item.dart";
import "package:photos/ui/collections/button/archived_button.dart";
import "package:photos/ui/collections/button/hidden_button.dart";
import "package:photos/ui/collections/button/trash_button.dart";
import "package:photos/ui/collections/button/uncategorized_button.dart";
import "package:photos/ui/collections/collection_list_page.dart";
import "package:photos/ui/collections/device/device_folders_grid_view.dart";
import "package:photos/ui/collections/device/device_folders_vertical_grid_view.dart";
import "package:photos/ui/collections/flex_grid_view.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/tabs/section_title.dart";
import "package:photos/ui/tabs/shared/all_quick_links_page.dart";
import "package:photos/ui/tabs/shared/empty_state.dart";
import "package:photos/ui/tabs/shared/quick_link_album_item.dart";
import "package:photos/ui/viewer/actions/album_selection_overlay_bar.dart";
import "package:photos/ui/viewer/actions/delete_empty_albums.dart";
import "package:photos/ui/viewer/gallery/collect_photos_card_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/gallery/empty_state.dart";
import "package:photos/ui/viewer/search_tab/contacts_section.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/standalone/debouncer.dart";

class UserCollectionsTab extends StatefulWidget {
  const UserCollectionsTab({super.key, this.selectedAlbums});

  final SelectedAlbums? selectedAlbums;

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
  late StreamSubscription<FavoritesServiceInitCompleteEvent>
      _favoritesServiceInitCompleteEvent;
  late StreamSubscription<AlbumSortOrderChangeEvent> _albumSortOrderChangeEvent;
  late StreamSubscription<TabChangedEvent> _tabChangeEvent;

  String _loadReason = "init";
  final _scrollController = ScrollController();
  final _debouncer = Debouncer(
    const Duration(seconds: 2),
    executionInterval: const Duration(seconds: 5),
    leading: true,
  );

  // This can be used to defer loading of widgets in this tab until the tab is
  // selected for a certain amount of time. This will not turn true until the
  // user has been in the tab for 500ms. This is to prevent loading widgets when
  // the user is just switching tabs quickly.
  final _canLoadDeferredWidgets = ValueNotifier<bool>(false);
  final _debouncerForDeferringLoad = Debouncer(
    const Duration(milliseconds: 500),
  );

  static const int _kOnEnteItemLimitCount = 12;
  static const heroTagPrefix = "outgoing_collection";
  static const maxThumbnailWidth = 224.0;
  static const crossAxisSpacing = 8.0;
  static const horizontalPadding = 16.0;
  @override
  void initState() {
    super.initState();
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _debouncer.run(() async {
        if (mounted) {
          _loadReason = event.reason;
          setState(() {});
        }
      });
    });
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      _debouncer.run(() async {
        if (mounted) {
          _loadReason = event.reason;
          setState(() {});
        }
      });
    });
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((event) {
      _loadReason = event.reason;
      setState(() {});
    });
    _favoritesServiceInitCompleteEvent =
        Bus.instance.on<FavoritesServiceInitCompleteEvent>().listen((event) {
      _debouncer.run(() async {
        _loadReason = event.reason;
        setState(() {});
      });
    });
    _albumSortOrderChangeEvent =
        Bus.instance.on<AlbumSortOrderChangeEvent>().listen((event) {
      _loadReason = event.reason;
      setState(() {});
    });

    _tabChangeEvent = Bus.instance.on<TabChangedEvent>().listen((event) {
      if (event.selectedIndex == 1) {
        _debouncerForDeferringLoad.run(() async {
          _logger.info("Loading deferred widgets in collections tab");
          if (mounted) {
            _canLoadDeferredWidgets.value = true;
            await _tabChangeEvent.cancel();
            Future.delayed(
              Duration.zero,
              () => _debouncerForDeferringLoad.cancelDebounceTimer(),
            );
          }
        });
      } else {
        _debouncerForDeferringLoad.cancelDebounceTimer();
        if (mounted) {
          _canLoadDeferredWidgets.value = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _logger.info("Building, trigger: $_loadReason");
    return FutureBuilder<List<Collection>>(
      future: CollectionsService.instance.getCollectionForOnEnteSection(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder<SharedCollections>(
            future: Future.value(CollectionsService.instance.getSharedCollections()),
            builder: (context, sharedSnapshot) {
              if (sharedSnapshot.hasData) {
                return _getCollectionsGalleryWidget(snapshot.data!, sharedSnapshot.data!);
              } else if (sharedSnapshot.hasError) {
                _logger.severe(
                  "Failed to load shared collections",
                  sharedSnapshot.error,
                  sharedSnapshot.stackTrace,
                );
                return _getCollectionsGalleryWidget(snapshot.data!, null);
              } else {
                return const EnteLoadingWidget();
              }
            },
          );
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }

  Widget _getCollectionsGalleryWidget(List<Collection> collections, SharedCollections? sharedCollections) {
    final TextStyle trashAndHiddenTextStyle =
        Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .color!
                  .withValues(alpha: 0.5),
            );

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: SectionOptions(
                onTap: () {
                  unawaited(
                    routeToPage(
                      context,
                      DeviceFolderVerticalGridView(
                        appTitle: SectionTitle(
                          title: AppLocalizations.of(context).onDevice,
                        ),
                        tag: "OnDeviceAppTitle",
                      ),
                    ),
                  );
                },
                Hero(
                  tag: "OnDeviceAppTitle",
                  child: SectionTitle(
                    title: AppLocalizations.of(context).onDevice,
                  ),
                ),
                trailingWidget: IconButtonWidget(
                  icon: Icons.chevron_right,
                  iconButtonType: IconButtonType.secondary,
                  iconColor: getEnteColorScheme(context).blurStrokePressed,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: DeviceFoldersGridView()),
            SliverToBoxAdapter(
              child: SectionOptions(
                onTap: () {
                  unawaited(
                    routeToPage(
                      context,
                      CollectionListPage(
                        collections,
                        sectionType: UISectionType.homeCollections,
                        appTitle: SectionTitle(
                          titleWithBrand: getOnEnteSection(context),
                        ),
                      ),
                    ),
                  );
                },
                SectionTitle(titleWithBrand: getOnEnteSection(context)),
                trailingWidget: IconButtonWidget(
                  icon: Icons.chevron_right,
                  iconButtonType: IconButtonType.secondary,
                  iconColor: getEnteColorScheme(context).blurStrokePressed,
                ),
              ),
            ),
            SliverToBoxAdapter(child: DeleteEmptyAlbums(collections)),
            Configuration.instance.hasConfiguredAccount()
                ? CollectionsFlexiGridViewWidget(
                    collections,
                    displayLimitCount: _kOnEnteItemLimitCount,
                    selectedAlbums: widget.selectedAlbums,
                    shrinkWrap: true,
                    shouldShowCreateAlbum: true,
                    enableSelectionMode: true,
                  )
                : const SliverToBoxAdapter(child: EmptyState()),
            SliverToBoxAdapter(
              child: Divider(
                color: getEnteColorScheme(context).strokeFaint,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
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
            ),
            // Add shared collections content
            if (sharedCollections != null) ..._getSharedCollectionsSlivers(sharedCollections),
            SliverToBoxAdapter(
              child:
                  SizedBox(height: 64 + MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
        AlbumSelectionOverlayBar(
          widget.selectedAlbums!,
          UISectionType.homeCollections,
          collections,
          showSelectAllButton: false,
        ),
      ],
    );
  }

  List<Widget> _getSharedCollectionsSlivers(SharedCollections collections) {
    const maxQuickLinks = 4;
    final numberOfQuickLinks = collections.quickLinks.length;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final int albumsCountInRow = max(screenWidth ~/ maxThumbnailWidth, 3);
    final totalHorizontalPadding = (albumsCountInRow - 1) * crossAxisSpacing;
    final sideOfThumbnail =
        (screenWidth - totalHorizontalPadding - horizontalPadding) /
            albumsCountInRow;
    const quickLinkTitleHeroTag = "quick_link_title";
    final SectionTitle sharedWithYou =
        SectionTitle(title: AppLocalizations.of(context).sharedWithYou);
    final SectionTitle sharedByYou =
        SectionTitle(title: AppLocalizations.of(context).sharedByYou);
    final colorTheme = getEnteColorScheme(context);

    List<Widget> slivers = [];

    // Add divider before shared content
    slivers.add(
      SliverToBoxAdapter(
        child: Divider(
          color: getEnteColorScheme(context).strokeFaint,
        ),
      ),
    );
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));

    // Shared with you section
    if (collections.incoming.isNotEmpty ||
        ((collections.incoming.length ?? 0) == 0 &&
            (collections.quickLinks.length ?? 0) == 0 &&
            (collections.outgoing.length ?? 0) == 0)) {
      slivers.add(
        SliverToBoxAdapter(
          child: SectionOptions(
            onTap: collections.incoming.isNotEmpty
                ? () {
                    unawaited(
                      routeToPage(
                        context,
                        CollectionListPage(
                          collections.incoming,
                          sectionType: UISectionType.incomingCollections,
                          tag: "incoming",
                          appTitle: sharedWithYou,
                        ),
                      ),
                    );
                  }
                : null,
            Hero(tag: "incoming", child: sharedWithYou),
            trailingWidget: collections.incoming.isNotEmpty
                ? IconButtonWidget(
                    icon: Icons.chevron_right,
                    iconButtonType: IconButtonType.secondary,
                    iconColor: colorTheme.blurStrokePressed,
                  )
                : null,
          ),
        ),
      );
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 2)));
      slivers.add(
        SliverToBoxAdapter(
          child: collections.incoming.isNotEmpty
              ? SizedBox(
                  height: sideOfThumbnail + 46,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: horizontalPadding / 2,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: horizontalPadding / 2,
                        ),
                        child: AlbumRowItemWidget(
                          collections.incoming[index],
                          sideOfThumbnail,
                          tag: "incoming",
                          showFileCount: true,
                        ),
                      );
                    },
                    itemCount: collections.incoming.length,
                  ),
                )
              : const IncomingAlbumEmptyState(),
        ),
      );
    }

    // Shared by you section
    if (collections.outgoing.isNotEmpty ||
        ((collections.incoming.length ?? 0) == 0 &&
            (collections.quickLinks.length ?? 0) == 0 &&
            (collections.outgoing.length ?? 0) == 0)) {
      slivers.add(
        SliverToBoxAdapter(
          child: SectionOptions(
            onTap: collections.outgoing.isNotEmpty
                ? () {
                    unawaited(
                      routeToPage(
                        context,
                        CollectionListPage(
                          collections.outgoing,
                          sectionType: UISectionType.outgoingCollections,
                          tag: "outgoing",
                          appTitle: sharedByYou,
                        ),
                      ),
                    );
                  }
                : null,
            Hero(tag: "outgoing", child: sharedByYou),
            trailingWidget: collections.outgoing.isNotEmpty
                ? IconButtonWidget(
                    icon: Icons.chevron_right,
                    iconButtonType: IconButtonType.secondary,
                    iconColor: colorTheme.blurStrokePressed,
                  )
                : null,
          ),
        ),
      );
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 2)));
      slivers.add(
        SliverToBoxAdapter(
          child: collections.outgoing.isNotEmpty
              ? SizedBox(
                  height: sideOfThumbnail + 46,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: horizontalPadding / 2,
                        ),
                        child: AlbumRowItemWidget(
                          collections.outgoing[index],
                          sideOfThumbnail,
                          tag: "outgoing",
                          showFileCount: true,
                        ),
                      );
                    },
                    itemCount: collections.outgoing.length,
                  ),
                )
              : const OutgoingAlbumEmptyState(),
        ),
      );
    }

    // Quick links section
    if (numberOfQuickLinks > 0) {
      slivers.add(
        SliverToBoxAdapter(
          child: SectionOptions(
            onTap: numberOfQuickLinks > maxQuickLinks
                ? () {
                    unawaited(
                      routeToPage(
                        context,
                        AllQuickLinksPage(
                          titleHeroTag: quickLinkTitleHeroTag,
                          quickLinks: collections.quickLinks,
                        ),
                      ),
                    );
                  }
                : null,
            Hero(
              tag: quickLinkTitleHeroTag,
              child: SectionTitle(
                title: AppLocalizations.of(context).quickLinks,
              ),
            ),
            trailingWidget: numberOfQuickLinks > maxQuickLinks
                ? IconButtonWidget(
                    icon: Icons.chevron_right,
                    iconButtonType: IconButtonType.secondary,
                    iconColor: colorTheme.blurStrokePressed,
                  )
                : null,
          ),
        ),
      );
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 2)));
      slivers.add(
        SliverToBoxAdapter(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.only(
              bottom: 12,
              left: 12,
              right: 12,
            ),
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  final thumbnail = await CollectionsService
                      .instance
                      .getCover(collections.quickLinks[index]);
                  final page = CollectionPage(
                    CollectionWithThumbnail(
                      collections.quickLinks[index],
                      thumbnail,
                    ),
                    tagPrefix: heroTagPrefix,
                  );
                  // ignore: unawaited_futures
                  routeToPage(context, page);
                },
                child: QuickLinkAlbumItem(
                  c: collections.quickLinks[index],
                ),
              );
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: 4);
            },
            itemCount: min(numberOfQuickLinks, maxQuickLinks),
          ),
        ),
      );
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 2)));
    slivers.add(
      SliverToBoxAdapter(
        child: ValueListenableBuilder(
          valueListenable: _canLoadDeferredWidgets,
          builder: (context, value, _) {
            return value
                ? FutureBuilder(
                    future: SearchService.instance
                        .getAllContactsSearchResults(kSearchSectionLimit),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ContactsSection(
                          snapshot.data as List<GenericSearchResult>,
                        );
                      } else if (snapshot.hasError) {
                        _logger.severe(
                          "failed to load contacts section",
                          snapshot.error,
                          snapshot.stackTrace,
                        );
                        return const EnteLoadingWidget();
                      } else {
                        return const EnteLoadingWidget();
                      }
                    },
                  )
                : const SizedBox.shrink();
          },
        ),
      ),
    );
    slivers.add(const SliverToBoxAdapter(child: CollectPhotosCardWidget()));
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 32)));

    return slivers;
  }

  @override
  void dispose() {
    _localFilesSubscription.cancel();
    _collectionUpdatesSubscription.cancel();
    _loggedOutEvent.cancel();
    _favoritesServiceInitCompleteEvent.cancel();
    _scrollController.dispose();
    _debouncer.cancelDebounceTimer();
    _debouncerForDeferringLoad.cancelDebounceTimer();
    _albumSortOrderChangeEvent.cancel();
    _tabChangeEvent.cancel();
    _canLoadDeferredWidgets.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
