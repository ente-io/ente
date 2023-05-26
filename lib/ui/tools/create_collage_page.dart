import "package:flutter/material.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file.dart";
import "package:photos/ui/viewer/file/zoomable_image.dart";

class CreateCollagePage extends StatefulWidget {
  final List<File> files;

  const CreateCollagePage(this.files, {super.key});

  @override
  State<CreateCollagePage> createState() => _CreateCollagePageState();
}

class _CreateCollagePageState extends State<CreateCollagePage> {
  final _logger = Logger("CreateCollagePage");

  @override
  Widget build(BuildContext context) {
    for (final file in widget.files) {
      _logger.info(file.displayName);
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(S.of(context).createCollage),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return VerticalSplit(widget.files[0], widget.files[1]);
  }

  Widget _getGrid() {
    return const TestGrid();
  }
}

class VerticalSplit extends StatelessWidget {
  const VerticalSplit(
    this.firstFile,
    this.secondFile, {
    super.key,
  });

  final File firstFile, secondFile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        axisDirection: AxisDirection.down,
        children: [
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 2,
            child: CollageItemWidget(firstFile),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 2,
            child: CollageItemWidget(secondFile),
          ),
        ],
      ),
    );
  }
}

class HorizontalSplit extends StatelessWidget {
  const HorizontalSplit(
    this.firstFile,
    this.secondFile, {
    super.key,
  });

  final File firstFile, secondFile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        axisDirection: AxisDirection.down,
        children: [
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 1,
            child: CollageItemWidget(firstFile),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 1,
            child: CollageItemWidget(secondFile),
          ),
        ],
      ),
    );
  }
}

class CollageItemWidget extends StatelessWidget {
  const CollageItemWidget(
    this.file, {
    super.key,
  });

  final File file;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      child: ZoomableImage(
        file,
        backgroundDecoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        tagPrefix: "collage_",
        shouldCover: true,
      ),
    );
  }
}

class Tile extends StatelessWidget {
  final String text;
  const Tile(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: Center(child: Text(text)),
    );
  }
}

class TestGrid extends StatelessWidget {
  const TestGrid({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      axisDirection: AxisDirection.down,
      children: const [
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1,
          child: Tile("0"),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1,
          child: Tile("1"),
        ),
        // StaggeredGridTile.count(
        //   crossAxisCellCount: 1,
        //   mainAxisCellCount: 1,
        //   child: Tile("2"),
        // ),
        // StaggeredGridTile.count(
        //   crossAxisCellCount: 1,
        //   mainAxisCellCount: 1,
        //   child: Tile("3"),
        // ),
        // StaggeredGridTile.count(
        //   crossAxisCellCount: 4,
        //   mainAxisCellCount: 2,
        //   child: Tile("4"),
        // ),
      ],
    );
  }
}
