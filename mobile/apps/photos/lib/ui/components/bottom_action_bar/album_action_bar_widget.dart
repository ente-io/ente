import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/theme/ente_theme.dart";

class AlbumActionBarWidget extends StatefulWidget {
  final SelectedAlbums? selectedAlbums;
  final VoidCallback? onCancel;
  const AlbumActionBarWidget({
    super.key,
    this.selectedAlbums,
    this.onCancel,
  });

  @override
  State<AlbumActionBarWidget> createState() => _AlbumActionBarWidgetState();
}

class _AlbumActionBarWidgetState extends State<AlbumActionBarWidget> {
  final ValueNotifier<int> _selectedAlbumNotifier = ValueNotifier(0);

  @override
  void initState() {
    widget.selectedAlbums?.addListener(_selectedAlbumListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.selectedAlbums?.removeListener(_selectedAlbumListener);
    _selectedAlbumNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder(
            valueListenable: _selectedAlbumNotifier,
            builder: (context, value, child) {
              return Text(
                S.of(context).selectedAlbums(
                      widget.selectedAlbums?.albums.length ?? 0,
                    ),
                style: textTheme.mini,
              );
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.onCancel?.call();
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.close,
                size: 16,
                color: textTheme.mini.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectedAlbumListener() {
    _selectedAlbumNotifier.value = widget.selectedAlbums?.albums.length ?? 0;
  }
}
