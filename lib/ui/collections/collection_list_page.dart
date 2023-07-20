import 'package:flutter/material.dart';
import "package:photos/models/collection.dart";
import "package:photos/ui/collections/flex_grid_view.dart";

class CollectionListPage extends StatelessWidget {
  final List<Collection>? collections;
  final Widget? appTitle;
  final double? initalScrollOffset;
  final String tag;

  const CollectionListPage(
    this.collections, {
    this.appTitle,
    this.initalScrollOffset,
    this.tag = "",
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller:
              ScrollController(initialScrollOffset: initalScrollOffset ?? 0),
          slivers: [
            SliverAppBar(
              elevation: 0,
              title: Hero(
                tag: tag,
                child: appTitle ?? const SizedBox.shrink(),
              ),
              floating: true,
            ),
            CollectionsFlexiGridViewWidget(
              collections,
              displayLimitCount: collections?.length ?? 0,
              tag: tag,
            ),
          ],
        ),
      ),
    );
  }
}
