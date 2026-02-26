import "package:flutter/material.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";

class AddedByWidget extends StatelessWidget {
  final EnteFile file;

  const AddedByWidget(this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    if (!file.isUploaded) {
      return const SizedBox.shrink();
    }
    String? addedBy;
    if (file.isOwner && file.isCollect) {
      addedBy = file.uploaderName;
    } else {
      final fileOwner = CollectionsService.instance
          .getFileOwner(file.ownerID!, file.collectionID);
      addedBy = fileOwner.displayName ?? fileOwner.email;
    }
    if (addedBy == null || addedBy.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 16),
      child: Text(
        AppLocalizations.of(context).addedBy(emailOrName: addedBy),
        style: getEnteTextTheme(context).miniMuted,
      ),
    );
  }
}
