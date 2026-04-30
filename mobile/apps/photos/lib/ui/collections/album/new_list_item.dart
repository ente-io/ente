import "package:ente_pure_utils/ente_pure_utils.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/services/collections_service.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";

class NewAlbumListItemWidget extends StatelessWidget {
  static const _rowHeight = 68.0;
  static const _cardRadius = 20.0;
  static const _thumbnailSize = 52.0;
  static const _thumbnailRadius = 12.0;

  final Future<void> Function(BuildContext context)? onTap;

  const NewAlbumListItemWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (onTap != null) {
          await onTap!(context);
          return;
        }

        final result = await showTextInputDialog(
          context,
          title: AppLocalizations.of(context).newAlbum,
          submitButtonLabel: AppLocalizations.of(context).create,
          hintText: AppLocalizations.of(context).enterAlbumName,
          alwaysShowSuccessState: false,
          initialValue: "",
          textCapitalization: TextCapitalization.words,
          popnavAfterSubmission: false,
          onSubmit: (String text) async {
            text = text.trim();
            if (text == "") {
              return;
            }

            try {
              final Collection c =
                  await CollectionsService.instance.createAlbum(text);

              // Close the dialog now so that it does not flash when leaving the album again.
              Navigator.of(context).pop();

              // ignore: unawaited_futures
              routeToPage(
                context,
                CollectionPage(CollectionWithThumbnail(c, null)),
              );
            } catch (e, s) {
              Logger("CreateNewAlbumListItemWidget")
                  .severe("Failed to rename album", e, s);
              rethrow;
            }
          },
        );

        if (result is Exception) {
          await showGenericErrorDialog(context: context, error: result);
        }
      },
      child: Container(
        height: _rowHeight,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.fill,
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Row(
          children: [
            Container(
              height: _thumbnailSize,
              width: _thumbnailSize,
              decoration: BoxDecoration(
                color: colorScheme.fill,
                borderRadius: BorderRadius.circular(_thumbnailRadius),
                border: Border.all(color: colorScheme.strokeDark),
              ),
              child: Center(
                child: Image.asset(
                  "assets/new_album_icon.png",
                  width: 20,
                  height: 20,
                  color: colorScheme.contentLight,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).addNew,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.small.copyWith(
                  color: colorScheme.contentLight,
                ),
              ),
            ),
            const SizedBox(width: 34, height: 34),
          ],
        ),
      ),
    );
  }
}
