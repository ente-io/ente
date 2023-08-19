import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
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
      subtitleSection: _objectTags(context, file),
      hasChipButtons: true,
    );
  }

  Future<List<ChipButtonWidget>> _objectTags(
    BuildContext context,
    File file,
  ) async {
    try {
      final chipButtons = <ChipButtonWidget>[];
      var objectTags = <String, double>{};
      final thumbnail = await getThumbnail(file);
      if (thumbnail != null) {
        objectTags = await ObjectDetectionService.instance.predict(thumbnail);
      }
      if (objectTags.isEmpty) {
        return [
          ChipButtonWidget(
            S.of(context).noResults,
            noChips: true,
          ),
        ];
      }
      // sort by values
      objectTags = Map.fromEntries(
        objectTags.entries.toList()
          ..sort((e1, e2) => e2.value.compareTo(e1.value)),
      );

      for (MapEntry<String, double> entry in objectTags.entries) {
        chipButtons.add(
          ChipButtonWidget(
            entry.key +
                (kDebugMode
                    ? "-" + (entry.value * 100).round().toString()
                    : ""),
          ),
        );
      }

      return chipButtons;
    } catch (e, s) {
      Logger("ObjctsItemWidget").info(e, s);
      return [];
    }
  }
}
