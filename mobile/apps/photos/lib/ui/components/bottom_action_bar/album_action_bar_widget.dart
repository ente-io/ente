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
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 1,
              child: ValueListenableBuilder(
                valueListenable: _selectedAlbumNotifier,
                builder: (context, value, child) {
                  return Text(
                    AppLocalizations.of(context).selectedAlbums(
                      count: widget.selectedAlbums?.albums.length ?? 0,
                    ),
                    style: textTheme.miniMuted,
                  );
                },
              ),
            ),
            Flexible(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    widget.onCancel?.call();
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      AppLocalizations.of(context).cancel,
                      style: textTheme.mini,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectedAlbumListener() {
    _selectedAlbumNotifier.value = widget.selectedAlbums?.albums.length ?? 0;
  }
}
