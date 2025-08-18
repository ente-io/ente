import 'dart:io';

import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/models/button_type.dart';
import 'package:ente_ui/components/text_input_widget.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import 'package:locker/utils/file_icon_utils.dart';
import 'package:locker/utils/snack_bar_utils.dart';
import 'package:path/path.dart' as path;

class FileUploadDialogResult {
  final String note;
  final List<Collection> selectedCollections;

  FileUploadDialogResult({
    required this.note,
    required this.selectedCollections,
  });
}

class FileUploadDialog extends StatefulWidget {
  final File file;
  final List<Collection> collections;
  final Collection? selectedCollection;

  const FileUploadDialog({
    super.key,
    required this.file,
    required this.collections,
    this.selectedCollection,
  });

  @override
  State<FileUploadDialog> createState() => _FileUploadDialogState();
}

class _FileUploadDialogState extends State<FileUploadDialog> {
  final TextEditingController _noteController = TextEditingController();
  final Set<int> _selectedCollectionIds = <int>{};
  List<Collection> _availableCollections = [];

  @override
  void initState() {
    super.initState();
    _availableCollections = List.from(widget.collections);
    if (widget.selectedCollection != null) {
      _selectedCollectionIds.add(widget.selectedCollection!.id);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleCollection(int collectionId) {
    setState(() {
      if (_selectedCollectionIds.contains(collectionId)) {
        _selectedCollectionIds.remove(collectionId);
      } else {
        _selectedCollectionIds.add(collectionId);
      }
    });
  }

  void _onCollectionsUpdated(List<Collection> updatedCollections) {
    setState(() {
      _availableCollections = updatedCollections;
    });
  }

  Future<void> _onCancel() async {
    Navigator.of(context).pop();
  }

  Future<void> _onSave() async {
    final selectedCollections = _availableCollections
        .where((c) => _selectedCollectionIds.contains(c.id))
        .toList();

    if (selectedCollections.isEmpty) {
      SnackBarUtils.showWarningSnackBar(
        context,
        context.l10n.pleaseSelectAtLeastOneCollection,
      );
      return;
    }

    final result = FileUploadDialogResult(
      note: _noteController.text.trim(),
      selectedCollections: selectedCollections,
    );

    Navigator.of(context).pop(result);
  }

  String get _fileName {
    return path.basename(widget.file.path);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Dialog(
      backgroundColor: colorScheme.backgroundElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FileIconUtils.getFileIcon(_fileName),
                  color: FileIconUtils.getFileIconColor(_fileName),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName,
                    style: textTheme.largeBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CollectionSelectionWidget(
              collections: _availableCollections,
              selectedCollectionIds: _selectedCollectionIds,
              onToggleCollection: _toggleCollection,
              onCollectionsUpdated: _onCollectionsUpdated,
            ),
            const SizedBox(height: 16),
            Text(
              'Note',
              style: textTheme.small.copyWith(
                color: colorScheme.textBase,
              ),
            ),
            const SizedBox(height: 8),
            TextInputWidget(
              hintText: context.l10n.optionalNote,
              initialValue: _noteController.text,
              onChange: (value) => _noteController.text = value,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: ButtonWidget(
                    buttonType: ButtonType.secondary,
                    labelText: context.l10n.cancel,
                    onTap: _onCancel,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: ButtonWidget(
                    buttonType: ButtonType.primary,
                    labelText: context.l10n.upload,
                    onTap: _onSave,
                    isDisabled: _selectedCollectionIds.isEmpty,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<FileUploadDialogResult?> showFileUploadDialog(
  BuildContext context, {
  required File file,
  required List<Collection> collections,
  Collection? selectedCollection,
}) async {
  return showDialog<FileUploadDialogResult>(
    context: context,
    barrierColor: getEnteColorScheme(context).backdropBase,
    builder: (context) => FileUploadDialog(
      file: file,
      collections: collections,
      selectedCollection: selectedCollection,
    ),
  );
}
