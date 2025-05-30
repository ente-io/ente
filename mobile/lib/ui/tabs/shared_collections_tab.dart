import 'dart:async';
import "dart:math";

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:photos/core/constants.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/events/tab_changed_event.dart";
import 'package:photos/events/user_logged_out_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/models/search/generic_search_result.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/album/row_item.dart";
import "package:photos/ui/collections/collection_list_page.dart";
import 'package:photos/ui/common/loading_widget.dart';
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import 'package:photos/ui/tabs/section_title.dart';
import "package:photos/ui/tabs/shared/all_quick_links_page.dart";
import "package:photos/ui/tabs/shared/empty_state.dart";
import "package:photos/ui/tabs/shared/quick_link_album_item.dart";
import "package:photos/ui/viewer/gallery/collect_photos_card_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/search_tab/contacts_section.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/standalone/debouncer.dart";

class SharedCollectionsTab extends StatefulWidget {
  const SharedCollectionsTab({super.key});

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
  final _debouncerForDeferringLoad = Debouncer(
    const Duration(milliseconds: 500),
  );

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
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((event) {
      setState(() {});
    });

    _tabChangeEvent = Bus.instance.on<TabChangedEvent>().listen((event) {
      if (event.selectedIndex == 2) {
        _debouncerForDeferringLoad.run(() async {
          _logger.info("Loading deferred widgets in shared collections tab");
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
    return FutureBuilder<SharedCollections>(
      future: Future.value(CollectionsService.instance.getSharedCollections()),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if ((snapshot.data?.incoming.length ?? 0) == 0 &&
              (snapshot.data?.quickLinks.length ?? 0) == 0 &&
              (snapshot.data?.outgoing.length ?? 0) == 0) {
            return const Center(child: SharedEmptyStateWidget());
          }
          return SafeArea(child: _getSharedCollectionsGallery(snapshot.data!));
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
    const maxQuickLinks = 4;
    final numberOfQuickLinks = collections.quickLinks.length;
    const quickLinkTitleHeroTag = "quick_link_title";
    final SectionTitle sharedWithYou =
        SectionTitle(title: S.of(context).sharedWithYou);
    final SectionTitle sharedByYou =
        SectionTitle(title: S.of(context).sharedByYou);
    final colorTheme = getEnteColorScheme(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
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
                                  sectionType:
                                      UISectionType.incomingCollections,
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
                  const SizedBox(height: 2),
                  collections.incoming.isNotEmpty
                      ? SizedBox(
                          height: maxThumbnailWidth + 24,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: AlbumRowItemWidget(
                                  collections.incoming[index],
                                  maxThumbnailWidth,
                                  tag: "incoming",
                                  showFileCount: false,
                                ),
                              );
                            },
                            itemCount: collections.incoming.length,
                          ),
                        )
                      : const IncomingAlbumEmptyState(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
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
                                  sectionType:
                                      UISectionType.outgoingCollections,
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
                  const SizedBox(height: 2),
                  collections.outgoing.isNotEmpty
                      ? SizedBox(
                          height: maxThumbnailWidth + 24,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: AlbumRowItemWidget(
                                  collections.outgoing[index],
                                  maxThumbnailWidth,
                                  tag: "outgoing",
                                  showFileCount: false,
                                ),
                              );
                            },
                            itemCount: collections.outgoing.length,
                          ),
                        )
                      : const OutgoingAlbumEmptyState(),
                ],
              ),
            ),
            numberOfQuickLinks > 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ),
                    child: Column(
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
                              title: S.of(context).quickLinks,
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
                    ),
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
                    : const EnteLoadingWidget();
              },
            ),
            const SizedBox(height: 4),
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
    _loggedOutEvent.cancel();
    _debouncer.cancelDebounceTimer();
    _debouncerForDeferringLoad.cancelDebounceTimer();
    _tabChangeEvent.cancel();
    _canLoadDeferredWidgets.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
