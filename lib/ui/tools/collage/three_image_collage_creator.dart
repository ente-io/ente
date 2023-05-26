import "package:flutter/widgets.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import "package:photos/ui/tools/collage/outlined_tile_widget.dart";

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
