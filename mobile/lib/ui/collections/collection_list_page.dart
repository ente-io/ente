import "dart:async";

import 'package:flutter/material.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/collection_updated_event.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/ui/collections/flex_grid_view.dart";

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

  @override
  void initState() {
    super.initState();
    collections = widget.collections;
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) async {
      unawaited(refreshCollections());
    });
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
