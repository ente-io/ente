import 'dart:io';

import 'package:ente_ui/components/base_bottom_sheet.dart';
import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/models/button_type.dart';
import 'package:ente_ui/components/text_input_widget.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import 'package:locker/utils/file_icon_utils.dart';
import 'package:path/path.dart' as path;

class FileUploadSheetResult {
  final String note;
  final List<Collection> selectedCollections;

  FileUploadSheetResult({
    required this.note,
    required this.selectedCollections,
  });
}

class FileUploadSheet extends StatefulWidget {
  final File file;
  final List<Collection> collections;
  final Collection? selectedCollection;

  const FileUploadSheet({
    super.key,
    required this.file,
    required this.collections,
    this.selectedCollection,
  });

  @override
  State<FileUploadSheet> createState() => _FileUploadSheetState();
}

class _FileUploadSheetState extends State<FileUploadSheet> {
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

  Future<void> _onSave() async {
    final selectedCollections = _availableCollections
        .where((c) => _selectedCollectionIds.contains(c.id))
        .toList();

    if (selectedCollections.isEmpty) {
      showToast(
        context,
        context.l10n.pleaseSelectAtLeastOneCollection,
      );
      return;
    }

    final result = FileUploadSheetResult(
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FileIconUtils.getFileIcon(
              _fileName,
              size: 24,
              showBackground: false,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _fileName,
                style: textTheme.body,
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
          title: context.l10n.collections,
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.note,
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
        SizedBox(
          width: double.infinity,
          child: ButtonWidget(
            buttonType: ButtonType.primary,
            labelText: context.l10n.upload,
            onTap: _onSave,
            isDisabled: _selectedCollectionIds.isEmpty,
          ),
        ),
      ],
    );
  }
}

Future<FileUploadSheetResult?> showFileUploadSheet(
  BuildContext context, {
  required File file,
  required List<Collection> collections,
  Collection? selectedCollection,
}) async {
  return showBaseBottomSheet<FileUploadSheetResult>(
    context,
    title: context.l10n.upload,
    headerSpacing: 20,
    isKeyboardAware: true,
    child: FileUploadSheet(
      file: file,
      collections: collections,
      selectedCollection: selectedCollection,
    ),
  );
}
