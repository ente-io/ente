import "package:flutter/material.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/ui/tools/collage/collage_common_widgets.dart";
import "package:photos/ui/tools/collage/collage_item_icon.dart";
import "package:photos/ui/tools/collage/collage_item_widget.dart";
import "package:photos/ui/tools/collage/collage_save_button.dart";
import "package:widgets_to_image/widgets_to_image.dart";

enum Variant {
  first,
  second,
}

class CollageWithFiveItems extends StatefulWidget {
  const CollageWithFiveItems(
    this.first,
    this.second,
    this.third,
    this.fourth,
    this.fifth, {
    super.key,
  });

  final EnteFile first, second, third, fourth, fifth;

  @override
  State<CollageWithFiveItems> createState() => _CollageWithFiveItemsState();
}

class _CollageWithFiveItemsState extends State<CollageWithFiveItems> {
  final _widgetsToImageController = WidgetsToImageController();
  Variant _variant = Variant.first;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        WidgetsToImage(
          controller: _widgetsToImageController,
          child: _getCollage(),
        ),
        const Expanded(child: SizedBox()),
        const CollageLayoutHeading(),
        _getLayouts(),
        const Padding(padding: EdgeInsets.all(4)),
        SaveCollageButton(_widgetsToImageController),
      ],
    );
  }

  Widget _getLayouts() {
    return Row(
      children: [
        CollageLayoutIconButton(
          child: FirstVariantIcon(
            isActive: _variant == Variant.first,
          ),
          onTap: () {
            setState(() {
              _variant = Variant.first;
            });
          },
        ),
        const Padding(padding: EdgeInsets.all(2)),
        CollageLayoutIconButton(
          child: SecondVariantIcon(
            isActive: _variant == Variant.second,
          ),
          onTap: () {
            setState(() {
              _variant = Variant.second;
            });
          },
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
          CollageItemWidget(widget.fourth),
          CollageItemWidget(widget.fifth),
        );
      case Variant.second:
        return SizedBox(
          width: 320,
          child: SecondVariant(
            CollageItemWidget(widget.first),
            CollageItemWidget(widget.second),
            CollageItemWidget(widget.third),
            CollageItemWidget(widget.fourth),
            CollageItemWidget(widget.fifth),
          ),
        );
    }
  }
}

class FirstVariant extends StatelessWidget {
  const FirstVariant(
    this.first,
    this.second,
    this.third,
    this.fourth,
    this.fifth, {
    super.key,
    this.mainAxisSpacing = 4,
    this.crossAxisSpacing = 4,
    this.color = Colors.white,
  });

  final Widget first, second, third, fourth, fifth;
  final double mainAxisSpacing, crossAxisSpacing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: StaggeredGrid.count(
          crossAxisCount: 6,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          axisDirection: AxisDirection.down,
          children: [
            StaggeredGridTile.count(
              crossAxisCellCount: 3,
              mainAxisCellCount: 3,
              child: first,
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 3,
              mainAxisCellCount: 2,
              child: second,
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 3,
              mainAxisCellCount: 2,
              child: third,
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 3,
              mainAxisCellCount: 3,
              child: fourth,
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 3,
              mainAxisCellCount: 2,
              child: fifth,
            ),
          ],
        ),
      ),
    );
  }
}

class SecondVariant extends StatelessWidget {
  const SecondVariant(
    this.first,
    this.second,
    this.third,
    this.fourth,
    this.fifth, {
    super.key,
    this.mainAxisSpacing = 4,
    this.crossAxisSpacing = 4,
    this.color = Colors.white,
  });

  final Widget first, second, third, fourth, fifth;
  final double mainAxisSpacing, crossAxisSpacing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: StaggeredGrid.count(
          crossAxisCount: 4,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          axisDirection: AxisDirection.down,
          children: [
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 2,
              child: first,
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 2,
              child: second,
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 4,
              mainAxisCellCount: 2,
              child: third,
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 2,
              child: fourth,
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 2,
              child: fifth,
            ),
          ],
        ),
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
    return CollageIconContainerWidget(
      width: 56,
      child: FirstVariant(
        CollageItemIcon(isActive: isActive),
        CollageItemIcon(isActive: isActive),
        CollageItemIcon(isActive: isActive),
        CollageItemIcon(isActive: isActive),
        CollageItemIcon(isActive: isActive),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        color: Colors.transparent,
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
    return CollageIconContainerWidget(
      child: SecondVariant(
        CollageItemIcon(isActive: isActive),
        CollageItemIcon(isActive: isActive),
        CollageItemIcon(isActive: isActive),
        CollageItemIcon(isActive: isActive),
        CollageItemIcon(isActive: isActive),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        color: Colors.transparent,
      ),
    );
  }
}
