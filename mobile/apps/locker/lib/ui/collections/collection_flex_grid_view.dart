import "dart:math";

import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/ui/pages/collection_page.dart";

class CollectionFlexGridViewWidget extends StatefulWidget {
  final List<Collection> collections;
  final Map<int, int> collectionFileCounts;
  const CollectionFlexGridViewWidget({
    super.key,
    required this.collections,
    required this.collectionFileCounts,
  });

  @override
  State<CollectionFlexGridViewWidget> createState() =>
      _CollectionFlexGridViewWidgetState();
}

class _CollectionFlexGridViewWidgetState
    extends State<CollectionFlexGridViewWidget> {
  late List<Collection> _displayedCollections;
  late Map<int, int> _collectionFileCounts;

  @override
  void initState() {
    super.initState();
    _displayedCollections = widget.collections;
    _collectionFileCounts = widget.collectionFileCounts;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      removeTop: true,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: min(_displayedCollections.length, 4),
        itemBuilder: (context, index) {
          final collection = _displayedCollections[index];
          final collectionName = collection.name ?? 'Unnamed Collection';

          return GestureDetector(
            onTap: () => _navigateToCollection(collection),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: getEnteColorScheme(context).fillFaint,
              ),
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        collectionName,
                        style: getEnteTextTheme(context).body.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n
                            .items(_collectionFileCounts[collection.id] ?? 0),
                        style: getEnteTextTheme(context).small.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                  if (collection.type == CollectionType.favorites)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.star,
                        color: getEnteColorScheme(context).primary500,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToCollection(Collection collection) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CollectionPage(collection: collection),
      ),
    );
  }
}
