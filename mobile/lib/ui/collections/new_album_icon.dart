import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

class NewAlbumIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final IconButtonType iconButtonType;
  const NewAlbumIcon({
    required this.icon,
    required this.iconButtonType,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButtonWidget(
      icon: icon,
      iconButtonType: iconButtonType,
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
              Logger("CreateNewAlbumIcon")
                  .severe("Failed to rename album", e, s);
              rethrow;
            }
          },
        );

        if (result is Exception) {
          await showGenericErrorDialog(context: context, error: result);
        }
      },
    );
  }
}
