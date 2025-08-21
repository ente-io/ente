import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';

//https://www.figma.com/design/SYtMyLBs5SAOkTbfMMzhqt/Ente-Visual-Design?node-id=39181-172209&t=3qmSZWpXF3ZC4JGN-1

class NewAlbumListItemWidget extends StatelessWidget {
  const NewAlbumListItemWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    const sideOfThumbnail = 60.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: sideOfThumbnail,
                    width: sideOfThumbnail,
                    color: Theme.of(context).brightness == Brightness.light
                        ? colorScheme.backdropBase
                        : colorScheme.backdropFaint,
                    child: Icon(
                      Icons.add_outlined,
                      color: colorScheme.strokeMuted,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    AppLocalizations.of(context).newAlbum,
                    style:
                        textTheme.body.copyWith(color: colorScheme.textMuted),
                  ),
                ),
              ],
            ),
            IgnorePointer(
              child: DottedBorder(
                dashPattern: const [4],
                color: colorScheme.strokeFaint,
                strokeWidth: 1,
                padding: const EdgeInsets.all(0),
                borderType: BorderType.RRect,
                radius: const Radius.circular(4),
                child: SizedBox(
                  //Have to decrease the height and width by 1 pt as the stroke
                  //dotted border gives is of strokeAlign.center, so 0.5 inside and
                  // outside. Here for the row, stroke should be inside so we
                  //decrease the size of this sizedBox by 1 (so it shrinks 0.5 from
                  //every side) so that the strokeAlign.center of this sizedBox
                  //looks like a strokeAlign.inside in the row.
                  height: sideOfThumbnail - 1,
                  //This width will work for this only if the row widget takes up the
                  //full size it's parent (stack).
                  width: constraints.maxWidth - 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
