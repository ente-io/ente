import "package:flutter/material.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file.dart";
import "package:photos/services/sync_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/zoomable_image.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/toast_util.dart";
import "package:widgets_to_image/widgets_to_image.dart";

class CreateCollagePage extends StatefulWidget {
  final List<File> files;

  const CreateCollagePage(this.files, {super.key});

  @override
  State<CreateCollagePage> createState() => _CreateCollagePageState();
}

class _CreateCollagePageState extends State<CreateCollagePage> {
  final _logger = Logger("CreateCollagePage");
  final _widgetsToImageController = WidgetsToImageController();
  bool _isLayoutVertical = false;

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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WidgetsToImage(
            controller: _widgetsToImageController,
            child: _getCollage(),
          ),
          const Padding(padding: EdgeInsets.all(12)),
          Text(S.of(context).collageLayout),
          const Padding(padding: EdgeInsets.all(4)),
          Row(
            children: [
              GestureDetector(
                child: HorizontalSplitIcon(
                  isActive: !_isLayoutVertical,
                ),
                onTap: () {
                  setState(() {
                    _isLayoutVertical = false;
                  });
                },
              ),
              const Padding(padding: EdgeInsets.all(2)),
              GestureDetector(
                child: VerticalSplitIcon(
                  isActive: _isLayoutVertical,
                ),
                onTap: () {
                  setState(() {
                    _isLayoutVertical = true;
                  });
                },
              ),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          ButtonWidget(
            buttonType: ButtonType.neutral,
            labelText: S.of(context).saveCollage,
            onTap: _onSaveClicked,
            shouldSurfaceExecutionStates: true,
          ),
        ],
      ),
    );
  }

  Future<void> _onSaveClicked() async {
    final bytes = await _widgetsToImageController.capture();
    final fileName = "ente_collage_" +
        DateTime.now().microsecondsSinceEpoch.toString() +
        ".jpeg";
    //Disabling notifications for assets changing to insert the file into
    //files db before triggering a sync.
    PhotoManager.stopChangeNotify();
    final AssetEntity? newAsset =
        await (PhotoManager.editor.saveImage(bytes!, title: fileName));
    final newFile = await File.fromAsset('', newAsset!);
    newFile.generatedID = await FilesDB.instance.insert(newFile);
    Bus.instance
        .fire(LocalPhotosUpdatedEvent([newFile], source: "collageSave"));
    SyncService.instance.sync();
    showShortToast(context, S.of(context).collageSaved);
    replacePage(
      context,
      DetailPage(
        DetailPageConfiguration([newFile], null, 0, "collage"),
      ),
    );
  }

  Widget _getCollage() {
    return _isLayoutVertical
        ? VerticalSplit(
            CollageItemWidget(widget.files[0]),
            CollageItemWidget(widget.files[1]),
          )
        : HorizontalSplit(
            CollageItemWidget(widget.files[0]),
            CollageItemWidget(widget.files[1]),
          );
  }

  Widget _getGrid() {
    return const TestGrid();
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

class OutlinedTile extends StatelessWidget {
  const OutlinedTile({
    super.key,
    this.isActive = false,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive
              ? getEnteColorScheme(context).strokeBase
              : getEnteColorScheme(context).strokeMuted,
          width: 2,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
    );
  }
}
