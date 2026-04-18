import "dart:async";
import "dart:math";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/album_sort_order_change_event.dart";
import "package:photos/events/app_mode_changed_event.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/events/memory_share_updated_event.dart";
import "package:photos/events/tab_changed_event.dart";
import "package:photos/events/user_logged_out_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/memory_share/memory_share.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/memory_share_service.dart";
import "package:photos/services/photos_contacts_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/album/row_item.dart";
import "package:photos/ui/collections/collection_list_page.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/banners/shared_empty_offline_state_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/sharing/memory_link_details_sheet.dart";
import "package:photos/ui/social/widgets/feed_preview_widget.dart";
import "package:photos/ui/tabs/section_title.dart";
import "package:photos/ui/tabs/shared/all_memory_links_page.dart";
import "package:photos/ui/tabs/shared/all_quick_links_page.dart";
import "package:photos/ui/tabs/shared/empty_state.dart";
import "package:photos/ui/tabs/shared/memory_link_item.dart";
import "package:photos/ui/tabs/shared/quick_link_album_item.dart";
import "package:photos/ui/viewer/gallery/collect_photos_card_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/search_tab/contacts_section.dart";

class SharedCollectionsTab extends StatefulWidget {
  const SharedCollectionsTab({super.key});

  @override
  State<SharedCollectionsTab> createState() => _SharedCollectionsTabState();
}

class _SharedCollectionsTabState extends State<SharedCollectionsTab>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger("SharedCollectionGallery");
  static const _sharedTabIndex = 2;
  static const _feedPreviewStartupDelay = Duration(seconds: 5);
  late StreamSubscription<LocalPhotosUpdatedEvent> _localFilesSubscription;
  late StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;
  late StreamSubscription<AlbumSortOrderChangeEvent> _albumSortOrderChangeEvent;
  late StreamSubscription<MemoryShareUpdatedEvent> _memoryShareUpdatedEvent;
  late StreamSubscription<UserLoggedOutEvent> _loggedOutEvent;
  late StreamSubscription<AppModeChangedEvent> _appModeChangedEvent;
  final _debouncer = Debouncer(
    const Duration(seconds: 2),
    executionInterval: const Duration(seconds: 5),
    leading: true,
  );
  static const heroTagPrefix = "outgoing_collection";
  late StreamSubscription<TabChangedEvent> _tabChangeEvent;

  // This can be used to defer loading of widgets in this tab until the tab is
  // selected for a certain amount of time. This will not turn true until the
  // user has been in the tab for 500ms. This is to prevent loading widgets when
  // the user is just switching tabs quickly.
  final _canLoadDeferredWidgets = ValueNotifier<bool>(false);
  final _canLoadFeedPreview = ValueNotifier<bool>(false);
  final _debouncerForDeferringLoad = Debouncer(
    const Duration(milliseconds: 500),
  );
  Timer? _feedPreviewStartupTimer;
  var _isOnSharedTab = false;
  var _tabChangeSubscriptionCancelled = false;

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
          debugPrint("SetState Shared Collections on ${event.reason}");
          setState(() {});
        }
      });
    });
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      _debouncer.run(() async {
        if (mounted) {
          debugPrint("SetState Shared Collections on ${event.reason}");
          setState(() {});
        }
      });
    });
    _albumSortOrderChangeEvent =
        Bus.instance.on<AlbumSortOrderChangeEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    _memoryShareUpdatedEvent =
        Bus.instance.on<MemoryShareUpdatedEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((event) {
      setState(() {});
    });
    _appModeChangedEvent =
        Bus.instance.on<AppModeChangedEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    _scheduleFeedPreviewFromSharedTabBuild();

    _tabChangeEvent = Bus.instance.on<TabChangedEvent>().listen((event) {
      _isOnSharedTab = event.selectedIndex == _sharedTabIndex;
      if (_isOnSharedTab) {
        _enableDeferredWidgetsAfterDwell();
        _enableFeedPreviewImmediately();
        _warmContactsForSharedTab();
      } else {
        if (!_canLoadDeferredWidgets.value) {
          _debouncerForDeferringLoad.cancelDebounceTimer();
        }
      }
    });
  }

  void _enableDeferredWidgetsAfterDwell() {
    if (_canLoadDeferredWidgets.value) {
      return;
    }
    _debouncerForDeferringLoad.run(() async {
      _logger.info("Loading deferred widgets in shared collections tab");
      if (mounted) {
        _canLoadDeferredWidgets.value = true;
        _maybeCancelTabChangeListener();
      }
    });
  }

  void _scheduleFeedPreviewFromSharedTabBuild() {
    if (_canLoadFeedPreview.value) {
      return;
    }
    _feedPreviewStartupTimer?.cancel();
    _feedPreviewStartupTimer = Timer(_feedPreviewStartupDelay, () {
      if (!mounted || _canLoadFeedPreview.value) {
        return;
      }
      _enableFeedPreview("shared-tab-build-delay-elapsed");
    });
  }

  void _enableFeedPreviewImmediately() {
    _enableFeedPreview("shared-tab-selected");
  }

  void _warmContactsForSharedTab() {
    if (!flagService.enableContact ||
        !Configuration.instance.hasConfiguredAccount() ||
        !PhotosContactsService.instance.needsWarmup) {
      return;
    }
    unawaited(_retryContactsWarmup());
  }

  Future<void> _retryContactsWarmup() async {
    try {
      await PhotosContactsService.instance.ensureReady();
    } catch (e, s) {
      _logger.warning(
        "Failed to warm contacts while entering shared tab",
        e,
        s,
      );
    }
  }

  void _enableFeedPreview(String reason) {
    if (_canLoadFeedPreview.value) {
      return;
    }
    _feedPreviewStartupTimer?.cancel();
    _feedPreviewStartupTimer = null;
    _logger.info("Loading feed preview in shared collections tab ($reason)");
    _canLoadFeedPreview.value = true;
    _maybeCancelTabChangeListener();
  }

  void _maybeCancelTabChangeListener() {
    if (!_canLoadDeferredWidgets.value || !_canLoadFeedPreview.value) {
      return;
    }
    _debouncerForDeferringLoad.cancelDebounceTimer();
    _feedPreviewStartupTimer?.cancel();
    _feedPreviewStartupTimer = null;
    if (!_tabChangeSubscriptionCancelled) {
      _tabChangeSubscriptionCancelled = true;
      unawaited(_tabChangeEvent.cancel());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool offlineUiMode =
        isOfflineMode && !Configuration.instance.hasConfiguredAccount();
    return FutureBuilder<SharedCollectionsAndMemoryLinks>(
      future: offlineUiMode
          ? Future.value(SharedCollectionsAndMemoryLinks.empty())
          : CollectionsService.instance.getSharedCollectionsAndMemoryLinks(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          if (offlineUiMode) {
            return const SafeArea(
              child: SharedEmptyOfflineStateWidget(),
            );
          }
          if (data.collections.incoming.isEmpty &&
              data.collections.quickLinks.isEmpty &&
              data.collections.outgoing.isEmpty &&
              data.memoryLinks.isEmpty) {
            return const Center(child: SharedEmptyStateWidget());
          }
          return SafeArea(
            child: _getSharedCollectionsGallery(
              data.collections,
              data.memoryLinks,
            ),
          );
        } else if (snapshot.hasError) {
          _logger.severe(
            "critical: failed to load share gallery",
            snapshot.error,
            snapshot.stackTrace,
          );
          return Center(
            child: Text(AppLocalizations.of(context).somethingWentWrong),
          );
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }

  Widget _getSharedCollectionsGallery(
    SharedCollections collections,
    List<MemoryShare> memoryLinks,
  ) {
    const maxQuickLinks = 4;
    const maxMemoryLinks = 4;
    final numberOfQuickLinks = collections.quickLinks.length;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final int albumsCountInRow = max(screenWidth ~/ maxThumbnailWidth, 3);
    final totalHorizontalPadding = (albumsCountInRow - 1) * crossAxisSpacing;
    final sideOfThumbnail =
        (screenWidth - totalHorizontalPadding - horizontalPadding) /
            albumsCountInRow;
    const quickLinkTitleHeroTag = "quick_link_title";
    const memoryLinkTitleHeroTag = "memory_link_title";
    final SectionTitle sharedWithYou =
        SectionTitle(title: AppLocalizations.of(context).sharedWithYou);
    final SectionTitle sharedByYou =
        SectionTitle(title: AppLocalizations.of(context).sharedByYou);
    final colorTheme = getEnteColorScheme(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: _canLoadFeedPreview,
              builder: (context, canLoad, _) {
                return canLoad
                    ? const FeedPreviewWidget()
                    : const SizedBox.shrink();
              },
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SectionOptions(
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
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButtonWidget(
                              icon: Icons.search,
                              iconButtonType: IconButtonType.secondary,
                              iconColor: colorTheme.blurStrokePressed,
                              onTap: () {
                                unawaited(
                                  routeToPage(
                                    context,
                                    CollectionListPage(
                                      collections.incoming,
                                      sectionType:
                                          UISectionType.incomingCollections,
                                      tag: "incoming",
                                      appTitle: sharedWithYou,
                                      startInSearchMode: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButtonWidget(
                              icon: Icons.chevron_right,
                              iconButtonType: IconButtonType.secondary,
                              iconColor: colorTheme.blurStrokePressed,
                            ),
                          ],
                        )
                      : null,
                ),
                const SizedBox(height: 2),
                collections.incoming.isNotEmpty
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
                              key: ValueKey(
                                'incoming_${collections.incoming[index].id}',
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
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SectionOptions(
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
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButtonWidget(
                              icon: Icons.search,
                              iconButtonType: IconButtonType.secondary,
                              iconColor: colorTheme.blurStrokePressed,
                              onTap: () {
                                unawaited(
                                  routeToPage(
                                    context,
                                    CollectionListPage(
                                      collections.outgoing,
                                      sectionType:
                                          UISectionType.outgoingCollections,
                                      tag: "outgoing",
                                      appTitle: sharedByYou,
                                      startInSearchMode: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButtonWidget(
                              icon: Icons.chevron_right,
                              iconButtonType: IconButtonType.secondary,
                              iconColor: colorTheme.blurStrokePressed,
                            ),
                          ],
                        )
                      : null,
                ),
                const SizedBox(height: 2),
                collections.outgoing.isNotEmpty
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
                              key: ValueKey(
                                'outgoing_${collections.outgoing[index].id}',
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
              ],
            ),
            numberOfQuickLinks > 0
                ? Column(
                    children: [
                      SectionOptions(
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
                      const SizedBox(height: 2),
                      if (numberOfQuickLinks > 0)
                        ListView.separated(
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
                    ],
                  )
                : const SizedBox.shrink(),
            memoryLinks.isNotEmpty
                ? Column(
                    children: [
                      SectionOptions(
                        onTap: memoryLinks.length > maxMemoryLinks
                            ? () {
                                unawaited(
                                  routeToPage(
                                    context,
                                    AllMemoryLinksPage(
                                      titleHeroTag: memoryLinkTitleHeroTag,
                                      memoryShares: memoryLinks,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        Hero(
                          tag: memoryLinkTitleHeroTag,
                          child: SectionTitle(
                            title: AppLocalizations.of(context).memoryLinks,
                          ),
                        ),
                        trailingWidget: memoryLinks.length > maxMemoryLinks
                            ? IconButtonWidget(
                                icon: Icons.chevron_right,
                                iconButtonType: IconButtonType.secondary,
                                iconColor: colorTheme.blurStrokePressed,
                              )
                            : null,
                      ),
                      const SizedBox(height: 2),
                      ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(
                          bottom: 12,
                          left: 12,
                          right: 12,
                        ),
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final share = memoryLinks[index];
                          final title = MemoryShareService.instance
                                  .getMemoryShareTitle(share) ??
                              "Memory link";
                          return GestureDetector(
                            onTap: () async {
                              final deleted = await showMemoryLinkDetailsSheet(
                                context,
                                shareUrl: share.url,
                                shareId: share.id,
                              );
                              if (deleted == true && mounted) {
                                setState(() {});
                              }
                            },
                            child: MemoryLinkAlbumItem(
                              title: title,
                              fileCount: share.fileCount,
                              previewUploadedFileID:
                                  share.previewUploadedFileID,
                            ),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 4);
                        },
                        itemCount: min(memoryLinks.length, maxMemoryLinks),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 2),
            ValueListenableBuilder(
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
            const CollectPhotosCardWidget(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _localFilesSubscription.cancel();
    _collectionUpdatesSubscription.cancel();
    _albumSortOrderChangeEvent.cancel();
    _memoryShareUpdatedEvent.cancel();
    _loggedOutEvent.cancel();
    _appModeChangedEvent.cancel();
    _debouncer.cancelDebounceTimer();
    _debouncerForDeferringLoad.cancelDebounceTimer();
    _feedPreviewStartupTimer?.cancel();
    if (!_tabChangeSubscriptionCancelled) {
      _tabChangeSubscriptionCancelled = true;
      unawaited(_tabChangeEvent.cancel());
    }
    _canLoadDeferredWidgets.dispose();
    _canLoadFeedPreview.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
