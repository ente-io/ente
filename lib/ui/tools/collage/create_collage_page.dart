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
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import 'package:photos/ui/tools/collage/two_image_collage_creator.dart';
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/toast_util.dart";
import "package:widgets_to_image/widgets_to_image.dart";

class CreateCollagePage extends StatelessWidget {
  final _logger = Logger("CreateCollagePage");
  final _widgetsToImageController = WidgetsToImageController();

  final List<File> files;

  CreateCollagePage(this.files, {super.key});

  @override
  Widget build(BuildContext context) {
    for (final file in files) {
      _logger.info(file.displayName);
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(S.of(context).createCollage),
      ),
      body: _getBody(context),
    );
  }

  Widget _getBody(BuildContext context) {
    final count = files.length;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          count == 2
              ? TwoImageCollageCreator(
                  files[0],
                  files[1],
                  _widgetsToImageController,
                )
              : _getGrid(),
          const SizedBox(
            height: 24,
          ),
          ButtonWidget(
            buttonType: ButtonType.neutral,
            labelText: S.of(context).saveCollage,
            onTap: () {
              return _onSaveClicked(context);
            },
            shouldSurfaceExecutionStates: true,
          ),
        ],
      ),
    );
  }

  Future<void> _onSaveClicked(context) async {
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

  Widget _getGrid() {
    return const TestGrid();
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
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      axisDirection: AxisDirection.down,
      children: const [
        StaggeredGridTile.count(
          crossAxisCellCount: 3,
          mainAxisCellCount: 1,
          child: Tile("1"),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 3,
          mainAxisCellCount: 1,
          child: Tile("2"),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 3,
          mainAxisCellCount: 1,
          child: Tile("3"),
        ),
      ],
    );
  }
}
