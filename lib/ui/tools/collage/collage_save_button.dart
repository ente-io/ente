import "package:flutter/widgets.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file.dart";
import "package:photos/services/sync_service.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/toast_util.dart";
import "package:widgets_to_image/widgets_to_image.dart";

class SaveCollageButton extends StatelessWidget {
  const SaveCollageButton(
    this.controller, {
    super.key,
  });

  final WidgetsToImageController controller;

  @override
  Widget build(BuildContext context) {
    return ButtonWidget(
      buttonType: ButtonType.neutral,
      labelText: S.of(context).saveCollage,
      onTap: () async {
        final bytes = await controller.capture();
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
      },
      shouldSurfaceExecutionStates: true,
    );
  }
}
