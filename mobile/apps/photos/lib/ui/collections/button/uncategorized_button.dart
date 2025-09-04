import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/hidden_service.dart';
import 'package:photos/ui/viewer/gallery/uncategorized_page.dart';
import 'package:photos/utils/navigation_util.dart';

class UnCategorizedCollections extends StatelessWidget {
  final TextStyle textStyle;

  const UnCategorizedCollections(
    this.textStyle, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Collection? collection = CollectionsService.instance
        .getActiveCollections()
        .firstWhereOrNull((e) => e.type == CollectionType.uncategorized);
    if (collection == null) {
      // create uncategorized collection if it's not already created
      CollectionsService.instance.getUncategorizedCollection().ignore();
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(0),
        side: BorderSide(
          width: 0.5,
          color: Theme.of(context).iconTheme.color!.withValues(alpha: 0.24),
        ),
      ),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const Padding(padding: EdgeInsets.all(6)),
                  FutureBuilder<int>(
                    future: collection == null
                        ? Future.value(0)
                        : CollectionsService.instance.getFileCount(collection),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data! > 0) {
                        return RichText(
                          text: TextSpan(
                            style: textStyle,
                            children: [
                              TextSpan(
                                text:
                                    AppLocalizations.of(context).uncategorized,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const TextSpan(text: "  \u2022  "),
                              TextSpan(
                                text: snapshot.data.toString(),
                              ),
                              //need to query in db and bring this value
                            ],
                          ),
                        );
                      } else {
                        return RichText(
                          text: TextSpan(
                            style: textStyle,
                            children: [
                              TextSpan(
                                text:
                                    AppLocalizations.of(context).uncategorized,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              //need to query in db and bring this value
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).iconTheme.color,
              ),
            ],
          ),
        ),
      ),
      onPressed: () async {
        if (collection != null) {
          // ignore: unawaited_futures
          routeToPage(
            context,
            UnCategorizedPage(collection),
          );
        }
      },
    );
  }
}
