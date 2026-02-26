import 'package:ente_ui/components/base_bottom_sheet.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import "package:locker/ui/components/gradient_button.dart";

class FileRestoreSheetResult {
  final List<Collection> selectedCollections;

  const FileRestoreSheetResult({
    required this.selectedCollections,
  });
}

class FileRestoreSheet extends StatefulWidget {
  final EnteFile file;
  final List<Collection> collections;

  const FileRestoreSheet({
    super.key,
    required this.file,
    required this.collections,
  });

  @override
  State<FileRestoreSheet> createState() => _FileRestoreSheetState();
}

class _FileRestoreSheetState extends State<FileRestoreSheet> {
  final Set<int> _selectedCollectionIds = <int>{};
  List<Collection> _availableCollections = [];

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
      FileRestoreSheetResult(selectedCollections: selectedCollections),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CollectionSelectionWidget(
          collections: _availableCollections,
          selectedCollectionIds: _selectedCollectionIds,
          onToggleCollection: _toggleCollection,
          onCollectionsUpdated: _onCollectionsUpdated,
          title: "",
          singleSelectionMode: true,
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
    );
  }
}

Future<FileRestoreSheetResult?> showFileRestoreSheet(
  BuildContext context, {
  required EnteFile file,
  required List<Collection> collections,
}) {
  return showBaseBottomSheet<FileRestoreSheetResult>(
    context,
    title: context.l10n.restore,
    headerSpacing: 20,
    child: FileRestoreSheet(
      file: file,
      collections: collections,
    ),
  );
}
