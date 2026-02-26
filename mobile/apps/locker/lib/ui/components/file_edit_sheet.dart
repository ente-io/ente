import 'package:ente_ui/components/base_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import 'package:locker/ui/components/form_text_input_widget.dart';
import "package:locker/ui/components/gradient_button.dart";
import 'package:locker/utils/collection_list_util.dart';

class FileEditSheetResult {
  final String title;
  final String caption;
  final List<Collection> selectedCollections;

  FileEditSheetResult({
    required this.title,
    required this.caption,
    required this.selectedCollections,
  });
}

class FileEditSheet extends StatefulWidget {
  final EnteFile file;
  final List<Collection> collections;
  final BuildContext snackBarContext;

  const FileEditSheet({
    super.key,
    required this.file,
    required this.collections,
    required this.snackBarContext,
  });

  @override
  State<FileEditSheet> createState() => _FileEditSheetState();
}

class _FileEditSheetState extends State<FileEditSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final Set<int> _selectedCollectionIds = <int>{};
  List<Collection> _availableCollections = [];

  @override
  void initState() {
    super.initState();

    _availableCollections = _filterCollections(widget.collections);

    _titleController.text = widget.file.displayName;

    _captionController.text = widget.file.caption ?? '';

    _initializeSelections();
  }

  Future<void> _initializeSelections() async {
    try {
      final existingCollections =
          await CollectionService.instance.getCollectionsForFile(widget.file);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedCollectionIds
          ..clear()
          ..addAll(
            existingCollections
                .where(
                  (collection) =>
                      collection.type != CollectionType.uncategorized,
                )
                .map((collection) => collection.id),
          );
      });
    } catch (_) {
      // Ignore failures; selections will remain empty.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
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
      _availableCollections = _filterCollections(updatedCollections);
      _selectedCollectionIds
          .removeWhere((id) => !_availableCollections.any((c) => c.id == id));
    });
  }

  List<Collection> _filterCollections(List<Collection> source) {
    final filtered = uniqueCollectionsById(source)
      ..removeWhere(
        (collection) => collection.type == CollectionType.uncategorized,
      );
    return filtered;
  }

  Future<void> _onSave() async {
    final selectedCollections = _availableCollections
        .where((c) => _selectedCollectionIds.contains(c.id))
        .toList();

    final result = FileEditSheetResult(
      title: _titleController.text.trim(),
      caption: _captionController.text.trim(),
      selectedCollections: selectedCollections,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTextInputWidget(
          controller: _titleController,
          labelText: context.l10n.title,
          hintText: context.l10n.enterNewTitle,
          maxLength: 200,
          shouldUseTextInputWidget: false,
        ),
        const SizedBox(height: 24),
        CollectionSelectionWidget(
          collections: _availableCollections,
          selectedCollectionIds: _selectedCollectionIds,
          onToggleCollection: _toggleCollection,
          onCollectionsUpdated: _onCollectionsUpdated,
          title: context.l10n.collections,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            onTap: () async {
              await _onSave();
            },
            text: context.l10n.save,
          ),
        ),
      ],
    );
  }
}

Future<FileEditSheetResult?> showFileEditSheet(
  BuildContext context, {
  required EnteFile file,
  required List<Collection> collections,
  BuildContext? snackBarContext,
}) async {
  return showBaseBottomSheet<FileEditSheetResult>(
    context,
    title: context.l10n.editItem,
    headerSpacing: 20,
    isKeyboardAware: true,
    child: FileEditSheet(
      file: file,
      collections: collections,
      snackBarContext: snackBarContext ?? context,
    ),
  );
}
