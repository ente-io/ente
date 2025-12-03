import "package:ente_ui/components/title_bar_title_widget.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import "package:locker/ui/components/gradient_button.dart";

class FileRestoreDialogResult {
  final List<Collection> selectedCollections;

  const FileRestoreDialogResult({
    required this.selectedCollections,
  });
}

class FileRestoreDialog extends StatefulWidget {
  final EnteFile file;
  final List<Collection> collections;

  const FileRestoreDialog({
    super.key,
    required this.file,
    required this.collections,
  });

  @override
  State<FileRestoreDialog> createState() => _FileRestoreDialogState();
}

class _FileRestoreDialogState extends State<FileRestoreDialog> {
  final Set<int> _selectedCollectionIds = <int>{};
  late List<Collection> _availableCollections;

  @override
  void initState() {
    super.initState();
    _availableCollections = List.from(widget.collections);
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

  Future<void> _onRestore() async {
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

    Navigator.of(context).pop(
      FileRestoreDialogResult(selectedCollections: selectedCollections),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Dialog(
      backgroundColor: colorScheme.backgroundElevated2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
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
              CollectionSelectionWidget(
                collections: _availableCollections,
                selectedCollectionIds: _selectedCollectionIds,
                onToggleCollection: _toggleCollection,
                onCollectionsUpdated: _onCollectionsUpdated,
                singleSelectionMode: true,
                titleWidget: TitleBarTitleWidget(
                  title: "Restore",
                  trailingWidgets: [
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
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onTap: _onRestore,
                  text: context.l10n.restore,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<FileRestoreDialogResult?> showFileRestoreDialog(
  BuildContext context, {
  required EnteFile file,
  required List<Collection> collections,
}) {
  return showDialog<FileRestoreDialogResult>(
    context: context,
    builder: (context) => FileRestoreDialog(
      file: file,
      collections: collections,
    ),
  );
}
