import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/theme/effects.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/collection_list_page.dart";
import "package:photos/ui/components/bottom_action_bar/album_action_bar_widget.dart";
import "package:photos/ui/components/bottom_action_bar/album_bottom_action_bar_widget.dart";

class AlbumSelectionOverlayBar extends StatefulWidget {
  final VoidCallback? onClose;
  final SelectedAlbums selectedAlbums;
  final List<Collection> collections;
  final Color? backgroundColor;
  final UISectionType sectionType;
  final bool showSelectAllButton;
  final VoidCallback? onCancel;

  const AlbumSelectionOverlayBar(
    this.selectedAlbums,
    this.sectionType,
    this.collections, {
    super.key,
    this.onClose,
    this.onCancel,
    this.backgroundColor,
    this.showSelectAllButton = false,
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
    widget.selectedAlbums.addListener(_selectedAlbumsListener);
  }

  @override
  void dispose() {
    widget.selectedAlbums.removeListener(_selectedAlbumsListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _hasSelectedAlbumsNotifier,
      builder: (context, value, child) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: _hasSelectedAlbumsNotifier.value
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          if (widget.showSelectAllButton)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: SelectAllAlbumsButton(
                                widget.selectedAlbums,
                                widget.collections,
                                backgroundColor: widget.backgroundColor,
                              ),
                            ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: AlbumActionBarWidget(
                              selectedAlbums: widget.selectedAlbums,
                              onCancel: () {
                                if (widget.selectedAlbums.albums.isNotEmpty) {
                                  widget.selectedAlbums.clearAll();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration:
                            BoxDecoration(boxShadow: shadowFloatFaintLight),
                        child: AlbumBottomActionBarWidget(
                          widget.selectedAlbums,
                          widget.sectionType,
                          onCancel: () {
                            if (widget.selectedAlbums.albums.isNotEmpty) {
                              widget.selectedAlbums.clearAll();
                            }
                          },
                          backgroundColor: widget.backgroundColor,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  _selectedAlbumsListener() {
    _hasSelectedAlbumsNotifier.value = widget.selectedAlbums.albums.isNotEmpty;
  }
}

class SelectAllAlbumsButton extends StatefulWidget {
  final SelectedAlbums selectedAlbums;
  final List<Collection> collections;
  final Color? backgroundColor;

  const SelectAllAlbumsButton(
    this.selectedAlbums,
    this.collections, {
    super.key,
    this.backgroundColor,
  });

  @override
  State<SelectAllAlbumsButton> createState() => _SelectAllAlbumsButtonState();
}

class _SelectAllAlbumsButtonState extends State<SelectAllAlbumsButton> {
  bool _allSelected = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_allSelected) {
            widget.selectedAlbums.clearAll();
          } else {
            widget.selectedAlbums.select(
              widget.collections.toSet(),
            );
          }
          _allSelected = !_allSelected;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? colorScheme.backgroundElevated2,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).selectAll,
              style: getEnteTextTheme(context).mini,
            ),
            const SizedBox(width: 4),
            ListenableBuilder(
              listenable: widget.selectedAlbums,
              builder: (context, _) {
                if (widget.selectedAlbums.albums.length ==
                    widget.collections.length) {
                  _allSelected = true;
                } else {
                  _allSelected = false;
                }
                return Icon(
                  _allSelected
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: _allSelected ? null : colorScheme.strokeBase,
                  size: 16,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
