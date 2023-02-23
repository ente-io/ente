import "dart:async";

import "package:flutter/cupertino.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/models/collection_items.dart";
import "package:photos/ui/collections/collection_item_widget.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/divider_widget.dart";

class AlbumHorizontalListWidget extends StatefulWidget {
  final Future<List<CollectionWithThumbnail>> Function() future;

  const AlbumHorizontalListWidget(
    this.future, {
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
    return FutureBuilder<List<CollectionWithThumbnail>>(
      future: widget.future(),
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
              height: 190,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: collectionsWithThumbnail.length,
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                      itemBuilder: (context, index) {
                        final item = collectionsWithThumbnail[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {},
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: CollectionItem(
                              item,
                              120,
                              shouldRender: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const DividerWidget(dividerType: DividerType.solid),
                ],
              ),
            ),
          );
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }
}
