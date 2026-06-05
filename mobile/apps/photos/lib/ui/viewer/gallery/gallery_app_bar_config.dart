import "package:flutter/widgets.dart";

class GalleryAppBarConfig {
  const GalleryAppBarConfig({
    required this.sliverBuilder,
    required this.pinnedHeight,
    required this.expandedHeight,
  }) : assert(expandedHeight >= pinnedHeight);

  final WidgetBuilder sliverBuilder;
  final double pinnedHeight;
  final double expandedHeight;

  double get collapseExtent => expandedHeight - pinnedHeight;

  Widget buildSliver(BuildContext context) => sliverBuilder(context);
}
