import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/collection/collection.dart';
import "package:photos/models/gallery_type.dart";
import "package:photos/models/ml/face/person.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/viewer/actions/file_selection_actions_widget.dart";

class BottomActionBarWidget extends StatelessWidget {
  final GalleryType galleryType;
  final Collection? collection;
  final PersonEntity? person;
  final String? clusterID;
  final SelectedFiles selectedFiles;
  final VoidCallback? onCancel;

  const BottomActionBarWidget({
    required this.galleryType,
    required this.selectedFiles,
    this.collection,
    this.person,
    this.clusterID,
    this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final widthOfScreen = MediaQuery.of(context).size.width;
    final colorScheme = getEnteColorScheme(context);
    final double leftRightPadding = widthOfScreen > restrictedMaxWidth
        ? (widthOfScreen - restrictedMaxWidth) / 2
        : 0;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 4,
        bottom: bottomPadding,
        right: leftRightPadding,
        left: leftRightPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          FileSelectionActionsWidget(
            galleryType,
            selectedFiles,
            collection: collection,
            person: person,
            clusterID: clusterID,
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
