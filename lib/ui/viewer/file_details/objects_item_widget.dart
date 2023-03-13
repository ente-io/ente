import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/models/file.dart";
import "package:photos/services/object_detection/object_detection_service.dart";
import "package:photos/ui/components/buttons/chip_button_widget.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/utils/thumbnail_util.dart";

class ObjectsItemWidget extends StatelessWidget {
  final File file;
  const ObjectsItemWidget(this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    return InfoItemWidget(
      key: const ValueKey("Objects"),
      leadingIcon: Icons.image_search_outlined,
      title: "Objects",
      subtitleSection: _objectTags(file),
      hasChipButtons: true,
    );
  }

  Future<List<ChipButtonWidget>> _objectTags(File file) async {
    try {
      final chipButtons = <ChipButtonWidget>[];
      final objectTags = await getThumbnail(file).then((data) {
        return ObjectDetectionService.instance.predict(data!);
      });
      for (String objectTag in objectTags) {
        chipButtons.add(ChipButtonWidget(objectTag));
      }
      if (chipButtons.isEmpty) {
        return const [
          ChipButtonWidget(
            "No results",
            noChips: true,
          )
        ];
      }
      return chipButtons;
    } catch (e, s) {
      Logger("ObjctsItemWidget").info(e, s);
      return [];
    }
  }
}
