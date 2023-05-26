import "package:flutter/widgets.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file.dart";
import "package:photos/ui/tools/collage/collage_item_widget.dart";
import "package:photos/ui/tools/collage/outlined_tile_widget.dart";
import "package:widgets_to_image/widgets_to_image.dart";

enum Variant {
  first,
  second,
  third,
}

class ThreeImageCollageCreator extends StatefulWidget {
  const ThreeImageCollageCreator(
    this.first,
    this.second,
    this.third,
    this.controller, {
    super.key,
  });

  final File first, second, third;
  final WidgetsToImageController controller;

  @override
  State<ThreeImageCollageCreator> createState() =>
      _ThreeImageCollageCreatorState();
}

class _ThreeImageCollageCreatorState extends State<ThreeImageCollageCreator> {
  Variant _variant = Variant.first;

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
                child: FirstVariantIcon(
                  isActive: _variant == Variant.first,
                ),
              ),
              onTap: () {
                setState(() {
                  _variant = Variant.first;
                });
              },
            ),
            const Padding(padding: EdgeInsets.all(2)),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SecondVariantIcon(
                  isActive: _variant == Variant.second,
                ),
              ),
              onTap: () {
                setState(() {
                  _variant = Variant.second;
                });
              },
            ),
            const Padding(padding: EdgeInsets.all(2)),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ThirdVariantIcon(
                  isActive: _variant == Variant.third,
                ),
              ),
              onTap: () {
                setState(() {
                  _variant = Variant.third;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _getCollage() {
    switch (_variant) {
      case Variant.first:
        return FirstVariant(
          CollageItemWidget(widget.first),
          CollageItemWidget(widget.second),
          CollageItemWidget(widget.third),
        );
      case Variant.second:
        return SecondVariant(
          CollageItemWidget(widget.first),
          CollageItemWidget(widget.second),
          CollageItemWidget(widget.third),
        );
      case Variant.third:
        return ThirdVariant(
          CollageItemWidget(widget.first),
          CollageItemWidget(widget.second),
          CollageItemWidget(widget.third),
        );
    }
  }
}

class FirstVariant extends StatelessWidget {
  const FirstVariant(
    this.first,
    this.second,
    this.third, {
    super.key,
    this.mainAxisSpacing = 4,
    this.crossAxisSpacing = 4,
  });

  final Widget first, second, third;
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
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: second,
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: third,
          ),
        ],
      ),
    );
  }
}

class SecondVariant extends StatelessWidget {
  const SecondVariant(
    this.first,
    this.second,
    this.third, {
    super.key,
    this.mainAxisSpacing = 4,
    this.crossAxisSpacing = 4,
  });

  final Widget first, second, third;
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
            mainAxisCellCount: 1,
            child: second,
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: third,
          ),
        ],
      ),
    );
  }
}

class ThirdVariant extends StatelessWidget {
  const ThirdVariant(
    this.first,
    this.second,
    this.third, {
    super.key,
    this.mainAxisSpacing = 4,
    this.crossAxisSpacing = 4,
  });

  final Widget first, second, third;
  final double mainAxisSpacing, crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: StaggeredGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        axisDirection: AxisDirection.down,
        children: [
          StaggeredGridTile.count(
            crossAxisCellCount: 3,
            mainAxisCellCount: 1,
            child: first,
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 3,
            mainAxisCellCount: 1,
            child: second,
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 3,
            mainAxisCellCount: 1,
            child: third,
          ),
        ],
      ),
    );
  }
}

class FirstVariantIcon extends StatelessWidget {
  const FirstVariantIcon({
    super.key,
    this.isActive = false,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: FirstVariant(
        OutlinedTile(isActive: isActive),
        OutlinedTile(isActive: isActive),
        OutlinedTile(isActive: isActive),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
    );
  }
}

class SecondVariantIcon extends StatelessWidget {
  const SecondVariantIcon({
    super.key,
    this.isActive = false,
  });
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: SecondVariant(
        OutlinedTile(isActive: isActive),
        OutlinedTile(isActive: isActive),
        OutlinedTile(isActive: isActive),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
    );
  }
}

class ThirdVariantIcon extends StatelessWidget {
  const ThirdVariantIcon({
    super.key,
    this.isActive = false,
  });
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: ThirdVariant(
        OutlinedTile(isActive: isActive),
        OutlinedTile(isActive: isActive),
        OutlinedTile(isActive: isActive),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
    );
  }
}
