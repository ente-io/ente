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
          'Collections',
          style: textTheme.small.copyWith(
            color: colorScheme.textBase,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.strokeFaint),
          ),
          child: _availableCollections.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.fillFaint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No collections available',
                          style: textTheme.body.copyWith(
                            color: colorScheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _createNewCollection,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary300.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: colorScheme.primary500,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: colorScheme.primary700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Create collection',
                                  style: textTheme.small.copyWith(
                                    color: colorScheme.primary700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Scrollbar(
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(3),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    padding: const EdgeInsets.all(6),
                    itemCount: _availableCollections.length +
                        1, // +1 for "Create New" option
                    itemBuilder: (context, index) {
                      if (index < _availableCollections.length) {
                        final collection = _availableCollections[index];
                        final isSelected = widget.selectedCollectionIds
                            .contains(collection.id);
                        final collectionName =
                            collection.name ?? 'Unnamed Collection';

                        return InkWell(
                          onTap: () => widget.onToggleCollection(collection.id),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary300.withOpacity(0.3)
                                  : colorScheme.fillFaint,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary500
                                    : colorScheme.strokeFaint,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                collectionName,
                                style: textTheme.small.copyWith(
                                  color: isSelected
                                      ? colorScheme.primary500
                                      : colorScheme.textBase,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }

                      return InkWell(
                        onTap: _createNewCollection,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.backgroundElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.strokeFaint.withOpacity(0.5),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_outlined,
                                  size: 14,
                                  color: colorScheme.textBase,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Collection',
                                    style: textTheme.small.copyWith(
                                      color: colorScheme.textBase,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<Collection> get availableCollections => _availableCollections;
}
