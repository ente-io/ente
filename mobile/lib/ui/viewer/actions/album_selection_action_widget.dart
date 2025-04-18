import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/ui/components/bottom_action_bar/selection_action_button_widget.dart";

class AlbumSelectionActionWidget extends StatefulWidget {
  final SelectedAlbums selectedAlbums;
  const AlbumSelectionActionWidget(
    this.selectedAlbums, {
    super.key,
  });

  @override
  State<AlbumSelectionActionWidget> createState() =>
      _AlbumSelectionActionWidgetState();
}

class _AlbumSelectionActionWidgetState
    extends State<AlbumSelectionActionWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.selectedAlbums.albums.isEmpty) {
      return const SizedBox();
    }
    final List<SelectionActionButton> items = [];
    items.add(
      SelectionActionButton(
        labelText: S.of(context).share,
        icon: Icons.adaptive.share,
        onTap: () {},
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: "Pin",
        icon: Icons.push_pin_rounded,
        onTap: () {},
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: S.of(context).delete,
        icon: Icons.delete_outline,
        onTap: () {},
      ),
    );
    items.add(
      SelectionActionButton(
        labelText: S.of(context).hide,
        icon: Icons.visibility_off_outlined,
        onTap: () {},
      ),
    );
    final scrollController = ScrollController();

    return MediaQuery(
      data: MediaQuery.of(context).removePadding(removeBottom: true),
      child: SafeArea(
        child: Scrollbar(
          radius: const Radius.circular(1),
          thickness: 2,
          controller: scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 4),
                  ...items,
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
