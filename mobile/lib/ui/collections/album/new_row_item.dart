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
    final enteColorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        onTap: () async {
          final result = await showTextInputDialog(
            context,
            title: S.of(context).newAlbum,
            submitButtonLabel: S.of(context).create,
            hintText: S.of(context).enterAlbumName,
            alwaysShowSuccessState: false,
            initialValue: "",
            textCapitalization: TextCapitalization.words,
            popnavAfterSubmission: false,
            onSubmit: (String text) async {
              if (text.trim() == "") {
                return;
              }

              try {
                final Collection c =
                    await CollectionsService.instance.createAlbum(text);
                // ignore: unawaited_futures
                await routeToPage(
                  context,
                  CollectionPage(CollectionWithThumbnail(c, null)),
                );
                Navigator.of(context).pop();
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
            DottedBorder(
              borderType: BorderType.RRect,
              strokeWidth: 1.5,
              borderPadding: const EdgeInsets.all(0.75),
              dashPattern: const [3.75, 3.75],
              radius: const Radius.circular(2.35),
              padding: EdgeInsets.zero,
              color: enteColorScheme.strokeFaint,
              child: SizedBox(
                height: height,
                width: width,
                child: Icon(
                  Icons.add,
                  color: enteColorScheme.strokeFaint,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              S.of(context).addNew,
              style: getEnteTextTheme(context).smallFaint,
            ),
          ],
        ),
      ),
    );
  }
}
