import "package:flutter/material.dart";
import "package:photos/models/file.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";

class AddedByWidget extends StatelessWidget {
  final File file;
  final int currentUserID;
  const AddedByWidget(this.file, this.currentUserID, {super.key});

  @override
  Widget build(BuildContext context) {
    if (file.uploadedFileID == null) {
      return const SizedBox.shrink();
    }
    String? addedBy;
    if (file.ownerID == currentUserID) {
      if (file.pubMagicMetadata!.uploaderName != null) {
        addedBy = file.pubMagicMetadata!.uploaderName;
      }
    } else {
      final fileOwner = CollectionsService.instance
          .getFileOwner(file.ownerID!, file.collectionID);
      addedBy = fileOwner.email;
    }
    if (addedBy == null || addedBy.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 16),
      child: Text(
        "Added by $addedBy",
        style: getEnteTextTheme(context).miniMuted,
      ),
    );
  }
}
