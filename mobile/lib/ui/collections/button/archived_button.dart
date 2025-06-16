import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/files_db.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/services/collections_service.dart";
import 'package:photos/ui/viewer/gallery/archive_page.dart';
import 'package:photos/utils/navigation_util.dart';

class ArchivedCollectionsButton extends StatelessWidget {
  final TextStyle textStyle;

  const ArchivedCollectionsButton(
    this.textStyle, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Set<int> hiddenCollectionId =
        CollectionsService.instance.getHiddenCollectionIds();
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
                    Icons.archive_outlined,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const Padding(padding: EdgeInsets.all(6)),
                  FutureBuilder<int>(
                    future: FilesDB.instance.archivedFilesCount(
                      archiveVisibility,
                      Configuration.instance.getUserID()!,
                      hiddenCollectionId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data! > 0) {
                        return RichText(
                          text: TextSpan(
                            style: textStyle,
                            children: [
                              TextSpan(
                                text: S.of(context).archive,
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
                                text: S.of(context).archive,
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
        // ignore: unawaited_futures
        routeToPage(
          context,
          ArchivePage(),
        );
      },
    );
  }
}
