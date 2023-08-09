import 'package:flutter/material.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/theme/effects.dart";
import 'package:photos/ui/components/bottom_action_bar/bottom_action_bar_widget.dart';

class FileSelectionOverlayBar extends StatefulWidget {
  final GalleryType galleryType;
  final SelectedFiles selectedFiles;
  final Collection? collection;
  final Color? backgroundColor;

  const FileSelectionOverlayBar(
    this.galleryType,
    this.selectedFiles, {
    this.collection,
    this.backgroundColor,
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
            firstChild: BottomActionBarWidget(
              selectedFiles: widget.selectedFiles,
              galleryType: widget.galleryType,
              collection: widget.collection,
              onCancel: () {
                if (widget.selectedFiles.files.isNotEmpty) {
                  widget.selectedFiles.clearAll();
                }
              },
              backgroundColor: widget.backgroundColor,
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
