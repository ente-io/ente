import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/blur_menu_item_widget.dart';
import 'package:photos/ui/components/bottom_action_bar/expanded_menu_widget.dart';

class FileSelectionActionWidget extends StatefulWidget {
  final GalleryType type;
  final Collection? collection;
  final DeviceCollection? deviceCollection;

  const FileSelectionActionWidget(
    this.type, {
    Key? key,
    this.collection,
    this.deviceCollection,
  }) : super(key: key);

  @override
  State<FileSelectionActionWidget> createState() =>
      _FileSelectionActionWidgetState();
}

class _FileSelectionActionWidgetState extends State<FileSelectionActionWidget> {
  @override
  Widget build(BuildContext context) {
    debugPrint('$runtimeType building  $mounted');
    final colorScheme = getEnteColorScheme(context);
    final List<List<BlurMenuItemWidget>> items = [];
    final List<BlurMenuItemWidget> firstList = [];
    if (widget.type.showAddToAlbum()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.add_outlined,
          labelText: "Add to album",
          menuItemColor: colorScheme.fillFaint,
        ),
      );
    }
    if (widget.type.showMoveToAlbum()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.arrow_forward_outlined,
          labelText: "Move to album",
          menuItemColor: colorScheme.fillFaint,
        ),
      );
    }

    if (widget.type.showRemoveFromAlbum()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.remove_outlined,
          labelText: "Remove from album",
          menuItemColor: colorScheme.fillFaint,
        ),
      );
    }

    if (widget.type.showDeleteOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.delete_outline,
          labelText: "Delete",
          menuItemColor: colorScheme.fillFaint,
        ),
      );
    }

    if (widget.type.showHideOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.visibility_off_outlined,
          labelText: "Hide",
          menuItemColor: colorScheme.fillFaint,
        ),
      );
    }
    if (widget.type.showArchiveOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.archive_outlined,
          labelText: "Archive",
          menuItemColor: colorScheme.fillFaint,
        ),
      );
    }

    if (widget.type.showFavoriteOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.favorite_border_rounded,
          labelText: "Favorite",
          menuItemColor: colorScheme.fillFaint,
        ),
      );
    }

    if (firstList.isNotEmpty) {
      items.add(firstList);
    }
    return ExpandedMenuWidget(
      items: items,
    );
  }
}
