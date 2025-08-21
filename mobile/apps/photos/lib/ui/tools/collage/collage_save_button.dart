import "package:flutter/widgets.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/services/sync/sync_service.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/utils/navigation_util.dart";
import "package:widgets_to_image/widgets_to_image.dart";

class SaveCollageButton extends StatelessWidget {
  final _logger = Logger("SaveCollageButton");

  SaveCollageButton(
    this.controller, {
    super.key,
  });

  final WidgetsToImageController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ButtonWidget(
        buttonType: ButtonType.neutral,
        labelText: AppLocalizations.of(context).saveCollage,
        onTap: () async {
          try {
            final bytes = await controller.capture();
            _logger.info('Size before compression = ${bytes!.length}');
            final compressedBytes = await FlutterImageCompress.compressWithList(
              bytes,
              quality: 80,
            );
            _logger.info('Size after compression = ${compressedBytes.length}');
            final fileName = "ente_collage_" +
                DateTime.now().microsecondsSinceEpoch.toString() +
                ".jpeg";
            final newAsset = await (PhotoManager.editor
                .saveImage(
              compressedBytes,
              filename: fileName,
              relativePath: "ente Collages",
            )
                .onError((err, st) async {
              return await (PhotoManager.editor.saveImage(
                compressedBytes,
                filename: fileName,
              ));
            }));
            final newFile = await EnteFile.fromAsset("ente Collages", newAsset);
            SyncService.instance.sync().ignore();
            showShortToast(context, AppLocalizations.of(context).collageSaved);
            replacePage(
              context,
              DetailPage(
                DetailPageConfiguration([newFile], 0, "collage"),
              ),
              result: true,
            );
          } catch (e, s) {
            _logger.severe(e, s);
            showShortToast(
              context,
              AppLocalizations.of(context).somethingWentWrong,
            );
          }
        },
        shouldSurfaceExecutionStates: true,
      ),
    );
  }
}
