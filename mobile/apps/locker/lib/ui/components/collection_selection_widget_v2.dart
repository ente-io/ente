import 'package:ente_components/ente_components.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:locker/extensions/collection_extension.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/utils/collection_actions.dart';
import 'package:locker/utils/collection_list_util.dart';
import 'package:locker/utils/file_icon_utils.dart';

class CollectionSelectionWidgetV2 extends StatefulWidget {
  final List<Collection> collections;
  final Set<int> selectedCollectionIds;
  final void Function(int) onToggleCollection;
  final void Function(List<Collection>) onCollectionsUpdated;

  const CollectionSelectionWidgetV2({
    super.key,
    required this.collections,
    required this.selectedCollectionIds,
    required this.onToggleCollection,
    required this.onCollectionsUpdated,
  });

  @override
  State<CollectionSelectionWidgetV2> createState() =>
      _CollectionSelectionWidgetV2State();
}

class _CollectionSelectionWidgetV2State
    extends State<CollectionSelectionWidgetV2> {
  final Map<int, Future<int>> _fileCounts = {};
  final List<Collection> _created = [];

  Future<void> _createCollection() async {
    final created = await CollectionActions.createCollection(context);
    if (created == null || !mounted) return;
    _created.insert(0, created);
    widget.onCollectionsUpdated([...widget.collections, created]);
    widget.onToggleCollection(created.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final l10n = context.strings;
    final collections = uniqueCollectionsById([
      ..._created,
      ...widget.collections,
    ]);
    return ScrollCard(
      showScrollbar: true,
      itemCount: collections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return MenuComponent(
            title: l10n.newCollection,
            titleColor: colors.primary,
            iconColor: colors.primary,
            leading: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
            onTap: _createCollection,
          );
        }
        final collection = collections[index - 1];
        return FutureBuilder<int>(
          key: ValueKey(collection.id),
          future: _fileCounts.putIfAbsent(
            collection.id,
            () => CollectionService.instance.getFileCount(collection),
          ),
          builder: (context, count) => MenuComponent(
            title: collection.type == CollectionType.uncategorized
                ? l10n.uncategorized
                : collection.displayName ?? l10n.unnamedCollection,
            titleMaxLines: 1,
            subtitle: l10n.itemCount(count: count.data ?? 0),
            leading: HugeIcon(
              icon: collection.type == CollectionType.favorites
                  ? HugeIcons.strokeRoundedStar
                  : HugeIcons.strokeRoundedFolder01,
            ),
            trailing: widget.selectedCollectionIds.contains(collection.id)
                ? const SelectionCheckBadge()
                : null,
            onTap: () => widget.onToggleCollection(collection.id),
          ),
        );
      },
    );
  }
}

class ScrollCard extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool showScrollbar;

  const ScrollCard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.showScrollbar = false,
  });

  @override
  State<ScrollCard> createState() => _ScrollCardState();
}

class _ScrollCardState extends State<ScrollCard> {
  final _controller = ScrollController();
  bool _hasMore = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(Notification notification) {
    if (notification
        case ScrollMetricsNotification(:final metrics) ||
            ScrollUpdateNotification(:final metrics)) {
      final hasMore = metrics.extentAfter > 0;
      if (hasMore != _hasMore) setState(() => _hasMore = hasMore);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: colors.strokeFaint),
        borderRadius: Radii.buttonBorder,
      ),
      child: ClipRRect(
        borderRadius: Radii.buttonBorder,
        child: NotificationListener<Notification>(
          onNotification: _onScroll,
          child: Stack(
            children: [
              Scrollbar(
                controller: _controller,
                thumbVisibility: widget.showScrollbar,
                child: ListView.separated(
                  controller: _controller,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: widget.itemCount,
                  separatorBuilder: (_, _) => ColoredBox(
                    color: colors.fillLight,
                    child: const DividerComponent(),
                  ),
                  itemBuilder: (context, index) => MenuGroupComponent(
                    borderRadius: MenuGroupComponent.itemBorderRadius(
                      index: index,
                      itemCount: widget.itemCount,
                    ),
                    items: [widget.itemBuilder(context, index)],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: Spacing.xxl,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _hasMore ? 1 : 0,
                    duration: Motion.quick,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.fillLight.withValues(alpha: 0),
                            colors.fillLight,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
