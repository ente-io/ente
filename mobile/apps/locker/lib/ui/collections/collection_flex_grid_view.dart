import "dart:math";

import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/extensions/collection_extension.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/ui/pages/collection_page.dart";

class CollectionFlexGridViewWidget extends StatelessWidget {
  final List<Collection> collections;
  const CollectionFlexGridViewWidget({
    super.key,
    required this.collections,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

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
          childAspectRatio: 2.4,
        ),
        itemCount: min(collections.length, 4),
        itemBuilder: (context, index) {
          final collection = collections[index];
          final collectionName =
              collection.displayName ?? context.l10n.unnamedCollection;

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CollectionPage(collection: collection),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.backdropBase,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    padding: const EdgeInsets.all(6),
                    child: collection.type == CollectionType.favorites
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedStar,
                            color: colorScheme.primary700,
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedWallet05,
                            color: colorScheme.textBase,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      collectionName,
                      style: textTheme.bodyBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
