import "package:ente_pure_utils/ente_pure_utils.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";

class NewAlbumRowItemWidget extends StatelessWidget {
  static const _cornerRadius = 20.0;

  final double height;
  final double width;

  const NewAlbumRowItemWidget({
    super.key,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      onTap: () async {
        final result = await showTextInputDialog(
          context,
          title: AppLocalizations.of(context).newAlbum,
          submitButtonLabel: AppLocalizations.of(context).create,
          hintText: AppLocalizations.of(context).enterAlbumName,
          alwaysShowSuccessState: false,
          initialValue: "",
          textCapitalization: TextCapitalization.words,
          popnavAfterSubmission: true,
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
              await routeToPage(
                context,
                CollectionPage(CollectionWithThumbnail(c, null)),
              );
            } catch (e, s) {
              Logger("CreateNewAlbumRowItemWidget")
                  .severe("Failed to rename album", e, s);
              rethrow;
            }
          },
        );

        if (result is Exception) {
          await showGenericErrorDialog(context: context, error: result);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_cornerRadius),
            child: Container(
              height: height,
              width: width,
              color: colorScheme.fill,
              child: Center(
                child: Image.asset(
                  "assets/new_album_icon.png",
                  width: 34,
                  height: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).addNew,
            style: getEnteTextTheme(context).smallFaint,
          ),
        ],
      ),
    );
  }
}
