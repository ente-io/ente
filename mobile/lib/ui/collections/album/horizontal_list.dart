import "dart:async";

import "package:flutter/cupertino.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/album/row_item.dart";
import "package:photos/ui/common/loading_widget.dart";

class AlbumHorizontalList extends StatefulWidget {
  final Future<List<Collection>> Function() collectionsFuture;
  final bool? hasVerifiedLock;

  const AlbumHorizontalList(
    this.collectionsFuture, {
    this.hasVerifiedLock,
    super.key,
  });

  @override
  State<AlbumHorizontalList> createState() => _AlbumHorizontalListState();
}

class _AlbumHorizontalListState extends State<AlbumHorizontalList> {
  late StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;
  late Logger _logger;

  @override
  void initState() {
    super.initState();
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      setState(() {});
    });
    _logger = Logger((_AlbumHorizontalListState).toString());
  }

  @override
  void dispose() {
    _collectionUpdatesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('$runtimeType widget build');
    return FutureBuilder<List<Collection>>(
      future: widget.collectionsFuture(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _logger.severe("failed to fetch albums", snapshot.error);
          return Text(S.of(context).somethingWentWrong);
        } else if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }
          final collections = snapshot.data as List<Collection>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    S.of(context).albums,
                    style: getEnteTextTheme(context).large,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 147, //139 + 8 (calculated from figma design)
                    child: ListView.separated(
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 4),
                      scrollDirection: Axis.horizontal,
                      itemCount: collections.length,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemBuilder: (context, index) {
                        final item = collections[index];
                        return AlbumRowItemWidget(
                          item,
                          120,
                          showFileCount: false,
                          hasVerifiedLock: widget.hasVerifiedLock,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.only(bottom: 24, top: 8),
            child: EnteLoadingWidget(),
          );
        }
      },
    );
  }
}
