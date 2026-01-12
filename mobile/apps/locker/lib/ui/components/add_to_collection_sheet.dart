import "package:ente_ui/components/base_bottom_sheet.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/ui/components/collection_selection_widget.dart";
import "package:locker/ui/components/gradient_button.dart";
import "package:locker/utils/collection_list_util.dart";

class AddToCollectionSheetResult {
  final List<Collection> selectedCollections;

  AddToCollectionSheetResult({
    required this.selectedCollections,
  });
}

class AddToCollectionSheet extends StatefulWidget {
  final List<Collection> collections;
  final BuildContext snackBarContext;

  const AddToCollectionSheet({
    super.key,
    required this.collections,
    required this.snackBarContext,
  });

  @override
  State<AddToCollectionSheet> createState() => _AddToCollectionSheetState();
}

class _AddToCollectionSheetState extends State<AddToCollectionSheet> {
  final Set<int> _selectedCollectionIds = <int>{};
  List<Collection> _availableCollections = [];

  @override
  void initState() {
    super.initState();
    _availableCollections = uniqueCollectionsById(widget.collections);
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
      _availableCollections = uniqueCollectionsById(updatedCollections);
    });
  }

  Future<void> _onSave() async {
    final selectedCollections = _availableCollections
        .where((c) => _selectedCollectionIds.contains(c.id))
        .toList();

    if (selectedCollections.isEmpty) {
      showToast(
        widget.snackBarContext,
        widget.snackBarContext.l10n.pleaseSelectAtLeastOneCollection,
      );
      return;
    }

    Navigator.of(context).pop(
      AddToCollectionSheetResult(
        selectedCollections: selectedCollections,
      ),
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

Future<AddToCollectionSheetResult?> showAddToCollectionSheet(
  BuildContext context, {
  required List<Collection> collections,
  BuildContext? snackBarContext,
}) async {
  final messengerContext = snackBarContext ?? context;
  return showBaseBottomSheet<AddToCollectionSheetResult>(
    context,
    title: context.l10n.addToCollection,
    headerSpacing: 20,
    child: AddToCollectionSheet(
      collections: collections,
      snackBarContext: messengerContext,
    ),
  );
}
