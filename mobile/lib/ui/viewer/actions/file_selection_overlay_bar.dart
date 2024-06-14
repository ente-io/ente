import 'package:flutter/material.dart';
import "package:photos/face/model/person.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/theme/effects.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/components/bottom_action_bar/bottom_action_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class FileSelectionOverlayBar extends StatefulWidget {
  final GalleryType galleryType;
  final SelectedFiles selectedFiles;
  final Collection? collection;
  final Color? backgroundColor;
  final PersonEntity? person;
  final int? clusterID;

  const FileSelectionOverlayBar(
    this.galleryType,
    this.selectedFiles, {
    this.collection,
    this.backgroundColor,
    this.person,
    this.clusterID,
    Key? key,
  }) : super(key: key);

  @override
  State<FileSelectionOverlayBar> createState() =>
      _FileSelectionOverlayBarState();
}

class _FileSelectionOverlayBarState extends State<FileSelectionOverlayBar> {
  final ValueNotifier<bool> _hasSelectedFilesNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    widget.selectedFiles.addListener(_selectedFilesListener);
  }

  @override
  void dispose() {
    _hasSelectedFilesNotifier.dispose();
    widget.selectedFiles.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '$runtimeType building with ${widget.selectedFiles.files.length}',
    );

    return Container(
      decoration: BoxDecoration(
        boxShadow: shadowFloatFaintLight,
      ),
      child: ValueListenableBuilder(
        valueListenable: _hasSelectedFilesNotifier,
        builder: (context, value, child) {
          return AnimatedCrossFade(
            firstCurve: Curves.easeInOutExpo,
            secondCurve: Curves.easeInOutExpo,
            sizeCurve: Curves.easeInOutExpo,
            crossFadeState: _hasSelectedFilesNotifier.value
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 400),
            firstChild: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SelectAllButton(backgroundColor: widget.backgroundColor),
                BottomActionBarWidget(
                  selectedFiles: widget.selectedFiles,
                  galleryType: widget.galleryType,
                  collection: widget.collection,
                  person: widget.person,
                  clusterID: widget.clusterID,
                  onCancel: () {
                    if (widget.selectedFiles.files.isNotEmpty) {
                      widget.selectedFiles.clearAll();
                    }
                  },
                  backgroundColor: widget.backgroundColor,
                ),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          );
        },
      ),
    );
  }

  _selectedFilesListener() {
    _hasSelectedFilesNotifier.value = widget.selectedFiles.files.isNotEmpty;
  }
}

class SelectAllButton extends StatefulWidget {
  final Color? backgroundColor;
  const SelectAllButton({super.key, required this.backgroundColor});

  @override
  State<SelectAllButton> createState() => _SelectAllButtonState();
}

class _SelectAllButtonState extends State<SelectAllButton> {
  bool _selectAll = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          final selectionState = SelectionState.of(context);
          if (_selectAll) {
            selectionState?.selectedFiles.clearAll();
          } else {
            selectionState?.selectedFiles
                .selectAll(selectionState.allGalleryFiles!.toSet());
          }
          _selectAll = !_selectAll;
        });
      },
      child: Container(
        color: getEnteColorScheme(context).backgroundElevated2,
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("All"),
            Icon(
              _selectAll ? Icons.check_circle : Icons.check_circle_outline,
              color:
                  _selectAll ? getEnteColorScheme(context).strokeMuted : null,
            ),
          ],
        ),
      ),
    );
  }
}
