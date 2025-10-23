import "package:ente_ui/components/buttons/gradient_button.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
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

  const FileEditDialog({
    super.key,
    required this.file,
    required this.collections,
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

    _availableCollections = List.from(widget.collections);

    _titleController.text = widget.file.displayName;

    _captionController.text = widget.file.caption ?? '';

    CollectionService.instance
        .getCollectionsForFile(widget.file)
        .then((fileCollections) {
      for (final collection in fileCollections) {
        _selectedCollectionIds.add(collection.id);
      }
      setState(() {});
    });
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

    final result = FileEditDialogResult(
      title: _titleController.text.trim(),
      caption: _captionController.text.trim(),
      selectedCollections: selectedCollections,
    );

    Navigator.of(context).pop(result);
  }

  String get _fileName {
    return widget.file.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Dialog(
      backgroundColor: colorScheme.backgroundBase,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.backdropBase,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                        Text(
                          "Rename your document",
                          style: textTheme.largeBold,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fileName,
                          style: textTheme.small.copyWith(
                            color: colorScheme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        color: colorScheme.backdropBase,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "Enter a new name for your document",
                  hintStyle: textTheme.body.copyWith(
                    color: colorScheme.textMuted,
                  ),
                  filled: true,
                  fillColor: colorScheme.fillFaint,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.strokeFaint,
                    ),
                  ),
                  counterText: "",
                ),
                maxLength: 200,
                style: textTheme.body.copyWith(
                  color: colorScheme.textBase,
                ),
              ),
              const SizedBox(height: 24),
              CollectionSelectionWidget(
                collections: _availableCollections,
                selectedCollectionIds: _selectedCollectionIds,
                onToggleCollection: _toggleCollection,
                onCollectionsUpdated: _onCollectionsUpdated,
                titleWidget: Text(
                  "Move to collection",
                  style: textTheme.largeBold,
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
      ),
    );
  }
}

Future<FileEditDialogResult?> showFileEditDialog(
  BuildContext context, {
  required EnteFile file,
  required List<Collection> collections,
}) async {
  return showDialog<FileEditDialogResult>(
    context: context,
    builder: (context) => FileEditDialog(
      file: file,
      collections: collections,
    ),
  );
}
