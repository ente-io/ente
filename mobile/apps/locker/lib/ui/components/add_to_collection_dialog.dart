import "package:ente_ui/components/buttons/gradient_button.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/ui/components/collection_selection_widget.dart";
import "package:locker/utils/snack_bar_utils.dart";

class AddToCollectionDialogResult {
  final List<Collection> selectedCollections;

  AddToCollectionDialogResult({
    required this.selectedCollections,
  });
}

class AddToCollectionDialog extends StatefulWidget {
  final List<Collection> collections;

  const AddToCollectionDialog({
    super.key,
    required this.collections,
  });

  @override
  State<AddToCollectionDialog> createState() => _AddToCollectionDialogState();
}

class _AddToCollectionDialogState extends State<AddToCollectionDialog> {
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

    Navigator.of(context).pop(
      AddToCollectionDialogResult(
        selectedCollections: selectedCollections,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Dialog(
      backgroundColor: colorScheme.backgroundBase,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CollectionSelectionWidget(
                collections: _availableCollections,
                selectedCollectionIds: _selectedCollectionIds,
                onToggleCollection: _toggleCollection,
                onCollectionsUpdated: _onCollectionsUpdated,
                titleWidget: TitleBarTitleWidget(
                  title: "Add to collection",
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

Future<AddToCollectionDialogResult?> showAddToCollectionDialog(
  BuildContext context, {
  required List<Collection> collections,
}) async {
  return showDialog<AddToCollectionDialogResult>(
    context: context,
    builder: (context) => AddToCollectionDialog(
      collections: collections,
    ),
  );
}
