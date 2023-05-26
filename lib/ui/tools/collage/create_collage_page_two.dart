import "package:flutter/widgets.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file.dart";
import "package:photos/ui/tools/collage/collage_item_widget.dart";
import "package:photos/ui/tools/collage/outlined_tile_widget.dart";
import "package:widgets_to_image/widgets_to_image.dart";

class TwoImageCollageCreator extends StatefulWidget {
  const TwoImageCollageCreator(
    this.first,
    this.second,
    this.controller, {
    super.key,
  });

  final File first, second;
  final WidgetsToImageController controller;

  @override
  State<TwoImageCollageCreator> createState() => _TwoImageCollageCreatorState();
}

class _TwoImageCollageCreatorState extends State<TwoImageCollageCreator> {
  bool _isLayoutVertical = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetsToImage(
          controller: widget.controller,
          child: _getCollage(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 0, 4),
          child: Text(S.of(context).collageLayout),
        ),
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: HorizontalSplitIcon(
                  isActive: !_isLayoutVertical,
                ),
              ),
              onTap: () {
                setState(() {
                  _isLayoutVertical = false;
                });
              },
            ),
            const Padding(padding: EdgeInsets.all(2)),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: VerticalSplitIcon(
                  isActive: _isLayoutVertical,
                ),
              ),
              onTap: () {
                setState(() {
                  _isLayoutVertical = true;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _getCollage() {
    return _isLayoutVertical
        ? VerticalSplit(
            CollageItemWidget(widget.first),
            CollageItemWidget(widget.second),
          )
        : HorizontalSplit(
            CollageItemWidget(widget.first),
            CollageItemWidget(widget.second),
          );
  }
}

class VerticalSplit extends StatelessWidget {
  const VerticalSplit(
    this.first,
    this.second, {
    super.key,
    this.mainAxisSpacing = 4,
    this.crossAxisSpacing = 4,
  });

  final Widget first, second;
  final double mainAxisSpacing, crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        axisDirection: AxisDirection.down,
        children: [
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 2,
            child: first,
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 2,
            child: second,
          ),
        ],
      ),
    );
  }
}

class HorizontalSplit extends StatelessWidget {
  const HorizontalSplit(
    this.first,
    this.second, {
    super.key,
    this.mainAxisSpacing = 4,
    this.crossAxisSpacing = 4,
  });

  final Widget first, second;
  final double mainAxisSpacing, crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        axisDirection: AxisDirection.down,
        children: [
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 1,
            child: first,
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 1,
            child: second,
          ),
        ],
      ),
    );
  }
}

class VerticalSplitIcon extends StatelessWidget {
  const VerticalSplitIcon({
    super.key,
    this.isActive = false,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: VerticalSplit(
        OutlinedTile(isActive: isActive),
        OutlinedTile(isActive: isActive),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
    );
  }
}

class HorizontalSplitIcon extends StatelessWidget {
  const HorizontalSplitIcon({
    super.key,
    this.isActive = false,
  });
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: HorizontalSplit(
        OutlinedTile(isActive: isActive),
        OutlinedTile(isActive: isActive),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
    );
  }
}
