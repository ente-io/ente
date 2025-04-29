import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/ui/viewer/gallery/component/grid/lazy_grid_view.dart";
import 'package:photos/ui/viewer/gallery/gallery.dart';

class GroupGallery extends StatelessWidget {
  final int photoGridSize;
  final List<EnteFile> files;
  final String tag;
  final GalleryLoader asyncLoader;
  final SelectedFiles? selectedFiles;
  final bool limitSelectionToOne;

  const GroupGallery({
    required this.photoGridSize,
    required this.files,
    required this.tag,
    required this.asyncLoader,
    required this.selectedFiles,
    required this.limitSelectionToOne,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const kRecycleLimit = 400;
    final List<Widget> childGalleries = [];
    final subGalleryItemLimit = photoGridSize * subGalleryMultiplier;

    for (int index = 0; index < files.length; index += subGalleryItemLimit) {
      childGalleries.add(
        LazyGridView(
          tag,
          files.sublist(
            index,
            min(index + subGalleryItemLimit, files.length),
          ),
          asyncLoader,
          selectedFiles,
          index == 0,
          files.length > kRecycleLimit,
          photoGridSize,
          limitSelectionToOne: limitSelectionToOne,
        ),
      );
    }

    return Column(
      children: childGalleries,
    );
  }
}
