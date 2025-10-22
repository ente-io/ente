import "package:dotted_border/dotted_border.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
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

  void _onUncategorizedSelected() {
    // Clear all selected collections when uncategorized is selected
    final collectionIdsCopy = Set<int>.from(widget.selectedCollectionIds);
    for (final id in collectionIdsCopy) {
      widget.onToggleCollection(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleBarTitleWidget(
          title: context.l10n.addToCollection,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            _buildUncategorizedChip(
              context.l10n.uncategorized,
              widget.selectedCollectionIds.isEmpty,
              _onUncategorizedSelected,
              colorScheme,
              textTheme,
            ),
            for (final collection in _availableCollections)
              _buildCollectionChip(
                collection: collection,
                isSelected:
                    widget.selectedCollectionIds.contains(collection.id),
                onTap: () => widget.onToggleCollection(collection.id),
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
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
    final collectionName = collection.name ?? context.l10n.unnamedCollection;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary700.withValues(alpha: 0.2)
              : colorScheme.fillFaint,
          borderRadius: const BorderRadius.all(Radius.circular(24.0)),
          border: Border.all(
            color: isSelected ? colorScheme.primary700 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          collectionName,
          style: textTheme.small.copyWith(
            color: isSelected ? colorScheme.primary700 : colorScheme.textBase,
          ),
        ),
      ),
    );
  }

  Widget _buildUncategorizedChip(
    String name,
    bool isSelected,
    VoidCallback onTap,
    colorScheme,
    textTheme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary700.withValues(alpha: 0.2)
              : colorScheme.fillFaint,
          borderRadius: const BorderRadius.all(Radius.circular(24.0)),
          border: Border.all(
            color: isSelected ? colorScheme.primary700 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          name,
          style: textTheme.small.copyWith(
            color: isSelected ? colorScheme.primary700 : colorScheme.textBase,
          ),
        ),
      ),
    );
  }

  Widget _buildNewCollectionChip({
    required colorScheme,
    required textTheme,
  }) {
    return GestureDetector(
      onTap: () async {
        await _createNewCollection();
      },
      child: DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          strokeWidth: 1,
          color: Color(0xFF6B6B6B),
          dashPattern: [5, 5],
          radius: Radius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 18,
              color: colorScheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.newCollection,
              style: textTheme.body.copyWith(
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
