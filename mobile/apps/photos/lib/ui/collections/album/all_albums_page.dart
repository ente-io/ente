import "package:flutter/material.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/ui/collections/flex_grid_view.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";

class AllAlbumsPage extends StatelessWidget {
  final List<Collection> collections;
  final String title;
  final bool? hasVerifiedLock;

  const AllAlbumsPage({
    required this.collections,
    required this.title,
    this.hasVerifiedLock,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: title,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverToBoxAdapter(
              child: CollectionsFlexiGridViewWidget(
                collections,
                displayLimitCount: collections.length,
                shrinkWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
