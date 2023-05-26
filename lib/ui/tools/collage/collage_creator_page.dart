import "package:flutter/material.dart";
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
import "package:photos/ui/tools/collage/collage_test_grid.dart";
import "package:photos/ui/tools/collage/collage_with_five_items.dart";
import "package:photos/ui/tools/collage/collage_with_four_items.dart";
import "package:photos/ui/tools/collage/collage_with_six_items.dart";
import "package:photos/ui/tools/collage/collage_with_three_items.dart";
import "package:photos/ui/tools/collage/collage_with_two_items.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/toast_util.dart";
import "package:widgets_to_image/widgets_to_image.dart";

class CollageCreatorPage extends StatelessWidget {
  static const int collageItemsMin = 2;
  static const int collageItemsMax = 6;

  final _logger = Logger("CreateCollagePage");
  final _widgetsToImageController = WidgetsToImageController();

  final List<File> files;

  CollageCreatorPage(this.files, {super.key});

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
    Widget collage;
    switch (count) {
      case 2:
        collage = CollageWithTwoItems(
          files[0],
          files[1],
          _widgetsToImageController,
        );
        break;
      case 3:
        collage = CollageWithThreeItems(
          files[0],
          files[1],
          files[2],
          _widgetsToImageController,
        );
        break;
      case 4:
        collage = CollageWithFourItems(
          files[0],
          files[1],
          files[2],
          files[3],
          _widgetsToImageController,
        );
        break;
      case 5:
        collage = CollageWithFiveItems(
          files[0],
          files[1],
          files[2],
          files[3],
          files[4],
          _widgetsToImageController,
        );
        break;
      case 6:
        collage = CollageWithSixItems(
          files[0],
          files[1],
          files[2],
          files[3],
          files[4],
          files[5],
          _widgetsToImageController,
        );
        break;
      default:
        collage = _getGrid();
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            width: 320,
            child: collage,
          ),
          const Expanded(child: SizedBox()),
          ButtonWidget(
            buttonType: ButtonType.neutral,
            labelText: S.of(context).saveCollage,
            onTap: () {
              return _onSaveClicked(context);
            },
            shouldSurfaceExecutionStates: true,
          ),
          const SafeArea(
            child: SizedBox(
              height: 12,
            ),
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
