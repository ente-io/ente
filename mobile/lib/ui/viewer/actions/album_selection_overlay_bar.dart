import 'package:flutter/material.dart';
import "package:photos/models/selected_albums.dart";
import "package:photos/theme/effects.dart";
import "package:photos/ui/components/bottom_action_bar/album_bottom_action_bar_widget.dart";

class AlbumSelectionOverlayBar extends StatefulWidget {
  final VoidCallback? onClose;
  final SelectedAlbums selectedAlbum;
  final Color? backgroundColor;

  const AlbumSelectionOverlayBar(
    this.selectedAlbum, {
    super.key,
    this.onClose,
    this.backgroundColor,
  });

  @override
  State<AlbumSelectionOverlayBar> createState() =>
      _AlbumSelectionOverlayBarState();
}

class _AlbumSelectionOverlayBarState extends State<AlbumSelectionOverlayBar> {
  final ValueNotifier<bool> _hasSelectedAlbumsNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    widget.selectedAlbum.addListener(_selectedAlbumsListener);
  }

  @override
  void dispose() {
    widget.selectedAlbum.removeListener(_selectedAlbumsListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _hasSelectedAlbumsNotifier,
      builder: (context, value, child) {
        return AnimatedCrossFade(
          firstCurve: Curves.easeInOutExpo,
          secondCurve: Curves.easeInOutExpo,
          sizeCurve: Curves.easeInOutExpo,
          crossFadeState: _hasSelectedAlbumsNotifier.value
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 400),
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(boxShadow: shadowFloatFaintLight),
                child: AlbumBottomActionBarWidget(
                  widget.selectedAlbum,
                  onCancel: () {
                    if (widget.selectedAlbum.albums.isNotEmpty) {
                      widget.selectedAlbum.clearAll();
                    }
                  },
                  backgroundColor: widget.backgroundColor,
                ),
              ),
            ],
          ),
          secondChild: const SizedBox(width: double.infinity),
        );
      },
    );
  }

  _selectedAlbumsListener() {
    _hasSelectedAlbumsNotifier.value = widget.selectedAlbum.albums.isNotEmpty;
  }
}
