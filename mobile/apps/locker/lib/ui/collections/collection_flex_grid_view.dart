import "dart:math";

import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/ui/pages/collection_page.dart";

class CollectionFlexGridViewWidget extends StatefulWidget {
  final List<Collection> collections;
  const CollectionFlexGridViewWidget({
    super.key,
    required this.collections,
  });

  @override
  State<CollectionFlexGridViewWidget> createState() =>
      _CollectionFlexGridViewWidgetState();
}

class _CollectionFlexGridViewWidgetState
    extends State<CollectionFlexGridViewWidget> {
  late List<Collection> _displayedCollections;

  @override
  void initState() {
    super.initState();
    _displayedCollections = widget.collections;
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
          childAspectRatio: 1.5,
        ),
        itemCount: min(_displayedCollections.length, 4),
        itemBuilder: (context, index) {
          final collection = _displayedCollections[index];
          final collectionName =
              collection.name ?? context.l10n.unnamedCollection;

          return GestureDetector(
            onTap: () => _navigateToCollection(collection),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: getEnteColorScheme(context).backdropBase,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: getEnteColorScheme(context).backgroundBase,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: collection.type == CollectionType.favorites
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedStar,
                            color: getEnteColorScheme(context).primary700,
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedWallet05,
                            color: getEnteColorScheme(context).iconColor,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    collectionName,
                    style: getEnteTextTheme(context).bodyBold,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: CollectionService.instance.getFileCount(collection),
                    builder: (context, snapshot) {
                      final fileCount = snapshot.data ?? 0;
                      return Text(
                        context.l10n.items(fileCount),
                        style: getEnteTextTheme(context).small.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.left,
                      );
                    },
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
