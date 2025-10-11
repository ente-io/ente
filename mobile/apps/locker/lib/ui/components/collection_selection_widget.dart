import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/utils/collection_actions.dart';

class CollectionSelectionWidget extends StatefulWidget {
  final List<Collection> collections;
  final Set<int> selectedCollectionIds;
  final Function(int) onToggleCollection;
  final Function(List<Collection>)? onCollectionsUpdated;

  const CollectionSelectionWidget({
    super.key,
    required this.collections,
    required this.selectedCollectionIds,
    required this.onToggleCollection,
    this.onCollectionsUpdated,
  });

  @override
  State<CollectionSelectionWidget> createState() =>
      _CollectionSelectionWidgetState();
}

class _CollectionSelectionWidgetState extends State<CollectionSelectionWidget> {
  List<Collection> _availableCollections = [];

  @override
  void initState() {
    super.initState();
    _availableCollections = List.from(widget.collections);
  }

  @override
  void didUpdateWidget(CollectionSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collections != widget.collections) {
      _availableCollections = List.from(widget.collections);
    }
  }

  Future<void> _createNewCollection() async {
    final newCollection = await CollectionActions.createCollection(context);

    if (newCollection != null) {
      setState(() {
        _availableCollections.add(newCollection);
      });

      widget.onToggleCollection(newCollection.id);

      widget.onCollectionsUpdated?.call(_availableCollections);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add to collection',
          style: textTheme.h3.copyWith(
            color: colorScheme.textBase,
          ),
        ),
        const SizedBox(height: 12),
        _availableCollections.isEmpty
            ? InkWell(
                onTap: _createNewCollection,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.strokeMuted,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: colorScheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'New collection',
                        style: textTheme.small.copyWith(
                          color: colorScheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Collection chips
                  for (final collection in _availableCollections)
                    _buildCollectionChip(
                      collection: collection,
                      isSelected:
                          widget.selectedCollectionIds.contains(collection.id),
                      onTap: () => widget.onToggleCollection(collection.id),
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  // "New collection" chip
                  _buildNewCollectionChip(
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildCollectionChip({
    required Collection collection,
    required bool isSelected,
    required VoidCallback onTap,
    required colorScheme,
    required textTheme,
  }) {
    final collectionName = collection.name ?? 'Unnamed Collection';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary300.withOpacity(0.15)
              : colorScheme.fillFaint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary700 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          collectionName,
          style: textTheme.small.copyWith(
            color: isSelected ? colorScheme.primary700 : colorScheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNewCollectionChip({
    required colorScheme,
    required textTheme,
  }) {
    return InkWell(
      onTap: _createNewCollection,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.strokeMuted,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 16,
              color: colorScheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              'New collection',
              style: textTheme.small.copyWith(
                color: colorScheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Collection> get availableCollections => _availableCollections;
}
