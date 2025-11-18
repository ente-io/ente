import 'dart:async';

import 'package:ente_events/event_bus.dart';
import "package:ente_ui/components/title_bar_title_widget.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
import 'package:locker/events/collections_updated_event.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/selected_collections.dart';
import 'package:locker/models/ui_section_type.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/trash/trash_service.dart';
import "package:locker/ui/components/empty_state_widget.dart";
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/ui/pages/collection_page.dart';
import 'package:locker/ui/pages/trash_page.dart';
import 'package:locker/utils/collection_sort_util.dart';
import 'package:logging/logging.dart';

class AllCollectionsPage extends StatefulWidget {
  final UISectionType viewType;
  final SelectedCollections? selectedCollections;

  const AllCollectionsPage({
    super.key,
    this.viewType = UISectionType.homeCollections,
    this.selectedCollections,
  });

  @override
  State<AllCollectionsPage> createState() => _AllCollectionsPageState();
}

class _AllCollectionsPageState extends State<AllCollectionsPage> {
  List<Collection> _sortedCollections = [];
  Collection? _uncategorizedCollection;
  int? _uncategorizedFileCount;
  bool _isLoading = true;
  String? _error;
  bool showTrash = false;
  bool showUncategorized = false;
  final _logger = Logger("AllCollectionsPage");
  StreamSubscription<CollectionsUpdatedEvent>? _collectionsUpdatedSub;

  @override
  void initState() {
    super.initState();
    _loadCollections();
    _collectionsUpdatedSub =
        Bus.instance.on<CollectionsUpdatedEvent>().listen((event) async {
      if (!mounted) return;
      await _loadCollections(showLoading: false);
    });
    if (widget.viewType == UISectionType.homeCollections) {
      showTrash = true;
      showUncategorized = true;
    }
  }

  @override
  void dispose() {
    _collectionsUpdatedSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCollections({bool showLoading = true}) async {
    if (mounted && showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      List<Collection> collections = [];

      if (widget.viewType == UISectionType.homeCollections) {
        collections = await CollectionService.instance.getCollections();
      } else if (widget.viewType == UISectionType.outgoingCollections ||
          widget.viewType == UISectionType.incomingCollections) {
        final sharedCollections =
            await CollectionService.instance.getSharedCollections();
        if (widget.viewType == UISectionType.outgoingCollections) {
          collections = sharedCollections.outgoing;
        } else if (widget.viewType == UISectionType.incomingCollections) {
          collections = sharedCollections.incoming;
        }
      }

      final regularCollections = <Collection>[];
      Collection? uncategorized;

      for (final collection in collections) {
        if (collection.type == CollectionType.uncategorized) {
          uncategorized = collection;
        } else {
          regularCollections.add(collection);
        }
      }

      CollectionSortUtil.sortCollections(regularCollections);

      _sortedCollections = List.from(regularCollections);
      _uncategorizedCollection =
          widget.viewType == UISectionType.homeCollections
              ? uncategorized
              : null;
      _uncategorizedFileCount = uncategorized != null &&
              widget.viewType == UISectionType.homeCollections
          ? (await CollectionService.instance
                  .getFilesInCollection(uncategorized))
              .length
          : 0;

      if (mounted) {
        if (showLoading) {
          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {});
        }
      }
    } catch (e) {
      _logger.severe("Failed to load collections", e);
      if (mounted && showLoading) {
        setState(() {
          _error = context.l10n.failedToLoadCollections(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_outlined,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(context),
          // TODO(aman): Uncomment when multi-select actions are restored.
          // CollectionSelectionOverlayBar(
          //   collection: _sortedCollections,
          //   selectedCollections: widget.selectedCollections!,
          //   viewType: widget.viewType,
          // ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final safeBottomInset = MediaQuery.of(context).padding.bottom;
    final bottomPadding = safeBottomInset + 24.0;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    //TODO: Fix issue when this is true
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCollections,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_sortedCollections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              EmptyStateWidget(
                assetPath: 'assets/empty_state.png',
                title: context.l10n.noCollections,
                subtitle: "",
                showBorder: false,
              ),
              const SizedBox(height: 20),
              if (_uncategorizedCollection != null && showUncategorized)
                _buildUncategorizedHook(),
              if (showTrash) _buildTrashHook(),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleBarTitleWidget(
            title: _getTitle(context),
          ),
          Text(
            _sortedCollections.length.toString() + " items",
            style: textTheme.smallMuted,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ItemListView(
              collections: _sortedCollections,
              // TODO(aman): pass selectedCollections when multi-select returns.
              selectedCollections: null,
              physics: const BouncingScrollPhysics(),
            ),
          ),
          if (_uncategorizedCollection != null && showUncategorized)
            _buildUncategorizedHook(),
          if (showTrash) _buildTrashHook(),
        ],
      ),
    );
  }

  Widget _buildTrashHook() {
    final textTheme = getEnteTextTheme(context);
    final borderRadius = BorderRadius.circular(20.0);

    return Container(
      margin: const EdgeInsets.only(top: 4.0, bottom: 16.0),
      child: InkWell(
        onTap: _openTrash,
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(30),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(50),
              width: 0.5,
            ),
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedDelete01,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(70),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.trash,
                  style: textTheme.large.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(60),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTrash() async {
    final trashFiles = await TrashService.instance.getTrashFiles();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrashPage(trashFiles: trashFiles),
      ),
    );
  }

  Widget _buildUncategorizedHook() {
    if (_uncategorizedCollection == null) return const SizedBox.shrink();

    final textTheme = getEnteTextTheme(context);
    final borderRadius = BorderRadius.circular(20.0);

    return Container(
      margin: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: InkWell(
        onTap: () => _openUncategorized(),
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(30),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(50),
              width: 0.5,
            ),
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedFolderUnknown,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(70),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      context.l10n.uncategorized,
                      style: textTheme.large.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_uncategorizedFileCount! > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: textTheme.small.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withAlpha(50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_uncategorizedFileCount!}',
                        style: textTheme.small.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withAlpha(70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(60),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUncategorized() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CollectionPage(
          collection: _uncategorizedCollection!,
          isUncategorized: true,
        ),
      ),
    );
  }

  String _getTitle(BuildContext context) {
    switch (widget.viewType) {
      case UISectionType.homeCollections:
        return context.l10n.collections;
      case UISectionType.outgoingCollections:
        return context.l10n.sharedByYou;
      case UISectionType.incomingCollections:
        return context.l10n.sharedWithYou;
    }
  }
}
