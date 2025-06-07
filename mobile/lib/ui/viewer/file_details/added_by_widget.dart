import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/magic_util.dart";

final _logger = Logger('AddedBy');

class AddedByWidget extends StatefulWidget {
  final EnteFile file;

  const AddedByWidget(this.file, {super.key});

  @override
  State<AddedByWidget> createState() => _AddedByWidgetState();
}

class _AddedByWidgetState extends State<AddedByWidget> {
  @override
  Widget build(BuildContext context) {
    if (!widget.file.isUploaded) {
      return const SizedBox.shrink();
    }
    String? addedBy;
    if (widget.file.isOwner && widget.file.isCollect) {
      addedBy = widget.file.uploaderName;
    } else {
      final fileOwner = CollectionsService.instance
          .getFileOwner(widget.file.ownerID!, widget.file.collectionID);
      addedBy = fileOwner.displayName ?? fileOwner.email;
    }
    if (addedBy == null || addedBy.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 16),
      child: GestureDetector(
        onTap: () async {
          if (!widget.file.isOwner) {
            return;
          }
          if (!widget.file.isCollect) {
            return;
          }
          final result = await showTextInputDialog(
            context,
            title: "Rename Uploader",
            submitButtonLabel: S.of(context).rename,
            initialValue: widget.file.uploaderName,
            maxLength: 50,
            onSubmit: (String text) async {
              text = text.trim();
              if (text.isEmpty) {
                return;
              }
              if (text == widget.file.uploaderName) {
                return;
              }
              Navigator.pop(context);
              await onRenameUploader(context, text);
              setState(() {});
            },
          );
          if (result is Exception) {
            _logger.severe("Failed to rename uploader");
            await showGenericErrorDialog(context: context, error: result);
          }
        },
        child: Text(
          S.of(context).addedBy(addedBy),
          style: getEnteTextTheme(context).miniMuted,
        ),
      ),
    );
  }

  Future<bool> onRenameUploader(
    BuildContext context,
    String newUploaderName,
  ) async {
    final filesToNewUploaderName = <EnteFile, String>{};
    filesToNewUploaderName[widget.file] = newUploaderName;
    return await editUploaderName(context, filesToNewUploaderName);
  }
}
