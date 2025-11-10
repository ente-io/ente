import "package:ente_ui/components/title_bar_title_widget.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import 'package:locker/ui/components/form_text_input_widget.dart';
import "package:locker/ui/components/gradient_button.dart";
import 'package:locker/utils/collection_list_util.dart';
import 'package:locker/utils/snack_bar_utils.dart';

class FileEditDialogResult {
  final String title;
  final String caption;
  final List<Collection> selectedCollections;

  FileEditDialogResult({
    required this.title,
    required this.caption,
    required this.selectedCollections,
  });
}

class FileEditDialog extends StatefulWidget {
  final EnteFile file;
  final List<Collection> collections;
  final BuildContext snackBarContext;

  const FileEditDialog({
    super.key,
    required this.file,
    required this.collections,
    required this.snackBarContext,
  });

  @override
  State<FileEditDialog> createState() => _FileEditDialogState();
}

class _FileEditDialogState extends State<FileEditDialog> {
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

  Future<void> _onCancel() async {
    Navigator.of(context).pop();
  }

  Future<void> _onSave() async {
    final selectedCollections = _availableCollections
        .where((c) => _selectedCollectionIds.contains(c.id))
        .toList();

    if (selectedCollections.isEmpty) {
      SnackBarUtils.showWarningSnackBar(
        widget.snackBarContext,
        widget.snackBarContext.l10n.pleaseSelectAtLeastOneCollection,
      );
      return;
    }

    final result = FileEditDialogResult(
      title: _titleController.text.trim(),
      caption: _captionController.text.trim(),
      selectedCollections: selectedCollections,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Dialog(
      backgroundColor: colorScheme.backgroundElevated2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated2,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitleBarTitleWidget(
                        title: context.l10n.editItem,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _onCancel,
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.backgroundElevated,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
              titleWidget: Text(
                context.l10n.collections,
                style: textTheme.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        ),
      ),
    );
  }
}

Future<FileEditDialogResult?> showFileEditDialog(
  BuildContext context, {
  required EnteFile file,
  required List<Collection> collections,
  BuildContext? snackBarContext,
}) async {
  return showDialog<FileEditDialogResult>(
    context: context,
    builder: (dialogContext) => FileEditDialog(
      file: file,
      collections: collections,
      snackBarContext: snackBarContext ?? context,
    ),
  );
}
