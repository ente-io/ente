import 'package:collection/collection.dart' show IterableExtension;
import 'package:dotted_border/dotted_border.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/extensions/collection_extension.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/utils/collection_actions.dart';
import 'package:locker/utils/collection_list_util.dart';

class CollectionSelectionWidget extends StatefulWidget {
  final List<Collection> collections;
  final Set<int> selectedCollectionIds;
  final Function(int) onToggleCollection;
  final Function(List<Collection>)? onCollectionsUpdated;
  final Widget? titleWidget;
  final bool singleSelectionMode;

  const CollectionSelectionWidget({
    super.key,
    required this.collections,
    required this.selectedCollectionIds,
    required this.onToggleCollection,
    this.onCollectionsUpdated,
    this.titleWidget,
    this.singleSelectionMode = false,
  });

  @override
  State<CollectionSelectionWidget> createState() =>
      _CollectionSelectionWidgetState();
}

class _CollectionSelectionWidgetState extends State<CollectionSelectionWidget> {
  List<Collection> _availableCollections = [];
  Collection? _uncategorizedCollection;

  @override
  void initState() {
    super.initState();
    _availableCollections = uniqueCollectionsById(widget.collections);
    _uncategorizedCollection = _availableCollections.firstWhereOrNull(
      (collection) => collection.type == CollectionType.uncategorized,
    );
    _availableCollections.removeWhere(
      (collection) => collection.type == CollectionType.uncategorized,
    );
  }

  @override
  void didUpdateWidget(CollectionSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collections != widget.collections) {
      _availableCollections = uniqueCollectionsById(widget.collections);
      _uncategorizedCollection = _availableCollections.firstWhereOrNull(
        (collection) => collection.type == CollectionType.uncategorized,
      );
      _availableCollections.removeWhere(
        (collection) => collection.type == CollectionType.uncategorized,
      );
    }
  }

  Future<void> _createNewCollection() async {
    final newCollection = await CollectionActions.createCollection(context);

    if (newCollection != null) {
      setState(() {
        _availableCollections.add(newCollection);
      });

      // In single selection mode, clear other selections before selecting the new one
      if (widget.singleSelectionMode) {
        final collectionIdsCopy = Set<int>.from(widget.selectedCollectionIds);
        for (final id in collectionIdsCopy) {
          widget.onToggleCollection(id);
        }
      }

      widget.onToggleCollection(newCollection.id);

      widget.onCollectionsUpdated?.call(_availableCollections);
    }
  }

  void _onCollectionTap(int collectionId) {
    if (widget.singleSelectionMode) {
      // In single selection mode, clear other selections first
      final collectionIdsCopy = Set<int>.from(widget.selectedCollectionIds);
      for (final id in collectionIdsCopy) {
        if (id != collectionId) {
          widget.onToggleCollection(id);
        }
      }
    }
    widget.onToggleCollection(collectionId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final containsUncategorized = _uncategorizedCollection != null;

    Widget? headerWidget = widget.titleWidget;
    if (headerWidget == null) {
      headerWidget = Text(
        context.l10n.collections,
        style: textTheme.body,
      );
    }

    bool _isHiddenHeader(Widget widget) {
      if (widget is SizedBox) {
        final isZeroWidth = widget.width != null && widget.width == 0;
        final isZeroHeight = widget.height != null && widget.height == 0;
        final noChild = widget.child == null;
        if ((isZeroWidth || isZeroHeight) && noChild) {
          return true;
        }
      }
      return false;
    }

    final bool hasVisibleHeader = !_isHiddenHeader(headerWidget);

    final chipItems = <_ChipItem>[];
    if (containsUncategorized) {
      chipItems.add(
        _ChipItem(
          widget: _buildUncategorizedChip(
            name: context.l10n.uncategorized,
            isSelected: widget.selectedCollectionIds
                .contains(_uncategorizedCollection?.id ?? -1),
            onTap: () {
              if (_uncategorizedCollection != null) {
                _onCollectionTap(_uncategorizedCollection!.id);
              }
            },
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          weight: context.l10n.uncategorized.length,
        ),
      );
    }

    for (final collection in _availableCollections) {
      final collectionName =
          collection.displayName ?? context.l10n.unnamedCollection;
      chipItems.add(
        _ChipItem(
          widget: _buildCollectionChip(
            collection: collection,
            isSelected: widget.selectedCollectionIds.contains(collection.id),
            onTap: () => _onCollectionTap(collection.id),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          weight: collectionName.length,
        ),
      );
    }

    final newCollectionChip = _ChipItem(
      widget: _buildNewCollectionChip(
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      weight: context.l10n.collectionLabel.length,
    );

    final topRowChips = <Widget>[];
    final bottomRowChips = <Widget>[];
    var topWeight = 0;
    var bottomWeight = newCollectionChip.weight;

    for (final item in chipItems) {
      if (topWeight <= bottomWeight) {
        topRowChips.add(item.widget);
        topWeight += item.weight;
      } else {
        bottomRowChips.add(item.widget);
        bottomWeight += item.weight;
      }
    }

    bottomRowChips.add(newCollectionChip.widget);

    List<Widget> _buildChipRow(List<Widget> rowChips) {
      final children = <Widget>[];
      for (var i = 0; i < rowChips.length; i++) {
        if (i != 0) {
          children.add(const SizedBox(width: 8));
        }
        children.add(rowChips[i]);
      }
      return children;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasVisibleHeader) ...[
          headerWidget,
          const SizedBox(height: 12),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: _buildChipRow(topRowChips)),
              if (bottomRowChips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: _buildChipRow(bottomRowChips)),
              ],
            ],
          ),
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
    final collectionName =
        collection.displayName ?? context.l10n.unnamedCollection;

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

  Widget _buildUncategorizedChip({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
    required colorScheme,
    required textTheme,
  }) {
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
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
                context.l10n.collectionLabel,
                style: textTheme.body.copyWith(
                  color: colorScheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Collection> get availableCollections => _availableCollections;
}

class _ChipItem {
  final Widget widget;
  final int weight;

  const _ChipItem({required this.widget, required this.weight});
}
