import "package:ente_components/ente_components.dart";
import "package:ente_strings/ente_strings.dart";
import "package:flutter/material.dart";
import "package:photos/ui/components/collection_share_badge.dart";

Future<bool?> showAlbumSortSheet(
  BuildContext context, {
  required bool ascending,
}) {
  return showBottomSheetComponent<bool>(
    context: context,
    builder: (sheetContext) => SingleChildScrollView(
      child: BottomSheetComponent(
        title: sheetContext.strings.sortPhotos,
        closeTooltip: sheetContext.strings.close,
        content: MenuGroupComponent(
          items: [
            for (final value in [false, true])
              Semantics(
                selected: value == ascending,
                child: MenuComponent(
                  title: value
                      ? sheetContext.strings.sortOldestFirst
                      : sheetContext.strings.sortNewestFirst,
                  trailing: value == ascending
                      ? const CollectionSelectedBadge()
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(value),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
