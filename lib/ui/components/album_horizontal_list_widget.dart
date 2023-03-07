import "dart:async";

import "package:flutter/cupertino.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/models/collection_items.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/collection_item_widget.dart";
import "package:photos/ui/common/loading_widget.dart";

class AlbumHorizontalListWidget extends StatefulWidget {
  final Future<List<CollectionWithThumbnail>> Function() collectionsFuture;

  const AlbumHorizontalListWidget(
    this.collectionsFuture, {
    Key? key,
  }) : super(key: key);

  @override
  State<AlbumHorizontalListWidget> createState() =>
      _AlbumHorizontalListWidgetState();
}

class _AlbumHorizontalListWidgetState extends State<AlbumHorizontalListWidget> {
  late StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;
  late Logger _logger;

  @override
  void initState() {
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      setState(() {});
    });
    _logger = Logger((_AlbumHorizontalListWidgetState).toString());
    super.initState();
  }

  @override
  void dispose() {
    _collectionUpdatesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('$runtimeType widget build');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            "Albums",
            style: getEnteTextTheme(context).large,
          ),
        ),
        FutureBuilder<List<CollectionWithThumbnail>>(
          future: widget.collectionsFuture(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              _logger.severe("failed to fetch albums", snapshot.error);
              return const Text("Something went wrong");
            } else if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final collectionsWithThumbnail =
                  snapshot.data as List<CollectionWithThumbnail>;
              return Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 147, //139 + 8 (calculated from figma design)
                  child: ListView.separated(
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: collectionsWithThumbnail.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      final item = collectionsWithThumbnail[index];
                      return CollectionItem(
                        item,
                        120,
                        shouldRender: true,
                        showFileCount: false,
                      );
                    },
                  ),
                ),
              );
            } else {
              return const EnteLoadingWidget();
            }
          },
        ),
      ],
    );
  }
}
