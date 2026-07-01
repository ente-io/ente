import 'package:collection/collection.dart' show IterableExtension;
import 'package:dotted_border/dotted_border.dart';
import "package:ente_components/ente_components.dart";
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

  final String title;

  const CollectionSelectionWidget({
    super.key,
    required this.collections,
    required this.selectedCollectionIds,
    required this.onToggleCollection,
    this.onCollectionsUpdated,
    required this.title,
  });

  @override
  State<CollectionSelectionWidget> createState() =>
      _CollectionSelectionWidgetState();
}

class _CollectionSelectionWidgetState extends State<CollectionSelectionWidget> {
  List<Collection> _availableCollections = [];
  Collection? _uncategorizedCollection;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

      widget.onToggleCollection(newCollection.id);

      widget.onCollectionsUpdated?.call([
        ?_uncategorizedCollection,
        ..._availableCollections,
      ]);
    }
  }

  void _onCollectionTap(int collectionId) {
    widget.onToggleCollection(collectionId);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final containsUncategorized = _uncategorizedCollection != null;

    final chips = <Widget>[];

    chips.add(_buildNewCollectionChip());

    if (containsUncategorized) {
      chips.add(
        TagChipComponent(
          label: context.l10n.uncategorized,
          state:
              widget.selectedCollectionIds.contains(
                _uncategorizedCollection?.id ?? -1,
              )
              ? TagChipComponentState.selected
              : TagChipComponentState.unselected,
          onTap: () {
            if (_uncategorizedCollection != null) {
              _onCollectionTap(_uncategorizedCollection!.id);
            }
          },
        ),
      );
    }

    for (final collection in _availableCollections) {
      final collectionName =
          collection.displayName ?? context.l10n.unnamedCollection;
      chips.add(
        TagChipComponent(
          label: collectionName,
          state: widget.selectedCollectionIds.contains(collection.id)
              ? TagChipComponentState.selected
              : TagChipComponentState.unselected,
          onTap: () => _onCollectionTap(collection.id),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty) ...[
          Text(widget.title, style: textTheme.body),
          const SizedBox(height: 12),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 168),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(right: 12, bottom: 12),
                child: Wrap(spacing: 8, runSpacing: 12, children: chips),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewCollectionChip() {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await _createNewCollection();
      },
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          strokeWidth: 1,
          padding: EdgeInsets.zero,
          color: colorScheme.textFaint,
          dashPattern: const [5, 5],
          radius: const Radius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: colorScheme.textMuted),
              const SizedBox(width: 6),
              Text(
                context.l10n.collectionLabel,
                style: textTheme.small.copyWith(color: colorScheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Collection> get availableCollections => _availableCollections;
}
