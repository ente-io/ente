import "package:dotted_border/dotted_border.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

class NewAlbumRowItemWidget extends StatelessWidget {
  final Color? color;
  final double height;
  final double width;
  const NewAlbumRowItemWidget({
    this.color,
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: height,
              width: width,
              color: Theme.of(context).brightness == Brightness.light
                  ? colorScheme.backdropBase
                  : colorScheme.backdropFaint,
              child: DottedBorder(
                borderType: BorderType.RRect,
                strokeWidth: 1.75,
                dashPattern: const [3.75, 3.75],
                radius: const Radius.circular(12),
                padding: EdgeInsets.zero,
                color: colorScheme.strokeFaint,
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: colorScheme.strokeFaint,
                  ),
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
