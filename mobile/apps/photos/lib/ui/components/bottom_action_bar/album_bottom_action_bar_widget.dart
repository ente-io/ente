import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/collection_list_page.dart";
import "package:photos/ui/components/bottom_action_bar/album_action_bar_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/viewer/actions/album_selection_action_widget.dart";

class AlbumBottomActionBarWidget extends StatelessWidget {
  final SelectedAlbums selectedAlbums;
  final VoidCallback? onCancel;
  final Color? backgroundColor;
  final UISectionType sectionType;

  const AlbumBottomActionBarWidget(
    this.selectedAlbums,
    this.sectionType, {
    super.key,
    this.backgroundColor,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final widthOfScreen = MediaQuery.sizeOf(context).width;
    final colorScheme = getEnteColorScheme(context);
    final double leftRightPadding = widthOfScreen > restrictedMaxWidth
        ? (widthOfScreen - restrictedMaxWidth) / 2
        : 0;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.backgroundElevated2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      padding: EdgeInsets.only(
        top: 4,
        bottom: bottomPadding,
        right: leftRightPadding,
        left: leftRightPadding,
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          AlbumSelectionActionWidget(selectedAlbums, sectionType),
          const DividerWidget(dividerType: DividerType.bottomBar),
          AlbumActionBarWidget(
            selectedAlbums: selectedAlbums,
            onCancel: onCancel,
          ),
        ],
      ),
    );
  }
}
