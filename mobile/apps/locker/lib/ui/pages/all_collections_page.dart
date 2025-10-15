import 'dart:async';

import 'package:ente_events/event_bus.dart';
import "package:ente_ui/components/title_bar_title_widget.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/events/collections_updated_event.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/selected_collections.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/trash/trash_service.dart';
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/ui/pages/collection_page.dart';
import 'package:locker/ui/pages/trash_page.dart';
import "package:locker/ui/viewer/actions/collection_selection_overlay_bar.dart";
import 'package:locker/utils/collection_sort_util.dart';
import 'package:logging/logging.dart';

enum UISectionType {
  incomingCollections,
  outgoingCollections,
  homeCollections,
}

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
  List<Collection> _allCollections = [];
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
      await _loadCollections();
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

  Future<void> _loadCollections() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      List<Collection> collections = [];

      if (widget.viewType == UISectionType.homeCollections) {
        collections = await CollectionService.instance.getCollections();
      } else {
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

      _allCollections = List.from(collections);
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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe("Failed to load collections", e);
      if (mounted) {
        setState(() {
          _error = context.l10n.failedToLoadCollections(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getEnteColorScheme(context).backgroundBase,
      appBar: AppBar(
        backgroundColor: getEnteColorScheme(context).backgroundBase,
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
      body: _buildBody(),
      bottomNavigationBar: widget.selectedCollections != null
          ? ListenableBuilder(
              listenable: widget.selectedCollections!,
              builder: (context, _) {
                return widget.selectedCollections!.hasSelections
                    ? CollectionSelectionOverlayBar(
                        collection: _sortedCollections,
                        selectedCollections: widget.selectedCollections!,
                      )
                    : const SizedBox.shrink();
              },
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.folder_open,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.noCollectionsFound,
                style: getEnteTextTheme(context).large.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleBarTitleWidget(
            title: _getTitle(context),
          ),
          Text(
            _allCollections.length.toString() + " items",
            style: getEnteTextTheme(context).smallMuted,
          ),
          Flexible(
            child: ItemListView(
              collections: _sortedCollections,
              selectedCollections: widget.selectedCollections,
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
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: InkWell(
        onTap: _openTrash,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(30),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(50),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(70),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.trash,
                  style: getEnteTextTheme(context).large.copyWith(
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

    return Container(
      margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: InkWell(
        onTap: () => _openUncategorized(),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(30),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(50),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_open_outlined,
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
                      style: getEnteTextTheme(context).large.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (_uncategorizedFileCount! > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: getEnteTextTheme(context).small.copyWith(
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
                        style: getEnteTextTheme(context).small.copyWith(
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
        builder: (context) =>
            CollectionPage(collection: _uncategorizedCollection!),
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
