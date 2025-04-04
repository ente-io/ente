import "dart:async";

import 'package:flutter/material.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/album_sort_order_change_event.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/collections/flex_grid_view.dart";
import "package:photos/ui/collections/new_album_icon.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/utils/local_settings.dart";

enum UISectionType {
  incomingCollections,
  outgoingCollections,
  homeCollections,
}

class CollectionListPage extends StatefulWidget {
  final List<Collection>? collections;
  final Widget? appTitle;
  final double? initialScrollOffset;
  final String tag;
  final UISectionType sectionType;

  const CollectionListPage(
    this.collections, {
    required this.sectionType,
    this.appTitle,
    this.initialScrollOffset,
    this.tag = "",
    super.key,
  });

  @override
  State<CollectionListPage> createState() => _CollectionListPageState();
}

class _CollectionListPageState extends State<CollectionListPage> {
  late StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;
  List<Collection>? collections;
  AlbumSortKey? sortKey;

  @override
  void initState() {
    super.initState();
    collections = widget.collections;
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) async {
      unawaited(refreshCollections());
    });
    sortKey = localSettings.albumSortKey();
  }

  @override
  void dispose() {
    _collectionUpdatesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          controller: ScrollController(
            initialScrollOffset: widget.initialScrollOffset ?? 0,
          ),
          slivers: [
            SliverAppBar(
              elevation: 0,
              title: Hero(
                tag: widget.tag,
                child: widget.appTitle ?? const SizedBox.shrink(),
              ),
              floating: true,
              actions: widget.sectionType == UISectionType.homeCollections
                  ? [
                      _sortMenu(collections!),
                    ]
                  : null,
            ),
            CollectionsFlexiGridViewWidget(
              collections,
              displayLimitCount: collections?.length ?? 0,
              tag: widget.tag,
            ),
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
          const NewAlbumIcon(
            icon: Icons.add_rounded,
            iconButtonType: IconButtonType.secondary,
          ),
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
                await localSettings.setAlbumSortKey(sortKey!);
                await refreshCollections();
                setState(() {});
                Bus.instance.fire(AlbumSortOrderChangeEvent());
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

  Future<void> refreshCollections() async {
    if (widget.sectionType == UISectionType.incomingCollections ||
        widget.sectionType == UISectionType.outgoingCollections) {
      final SharedCollections sharedCollections =
          CollectionsService.instance.getSharedCollections();
      if (widget.sectionType == UISectionType.incomingCollections) {
        collections = sharedCollections.incoming;
      } else {
        collections = sharedCollections.outgoing;
      }
    } else if (widget.sectionType == UISectionType.homeCollections) {
      collections =
          await CollectionsService.instance.getCollectionForOnEnteSection();
    }
    if (mounted) {
      setState(() {});
    }
  }
}
