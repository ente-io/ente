import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/thumbnail_list_item.dart";

//https://www.figma.com/design/SYtMyLBs5SAOkTbfMMzhqt/Ente-Visual-Design?node-id=39181-172209&t=3qmSZWpXF3ZC4JGN-1

class NewAlbumListItemWidget extends StatelessWidget {
  const NewAlbumListItemWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return ThumbnailListItem(
      backgroundColor: thumbnailListItemBackgroundColor(context),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(
          ThumbnailListItem.defaultLeadingRadius,
        ),
        child: Container(
          color: Theme.of(context).brightness == Brightness.light
              ? colorScheme.backdropBase
              : colorScheme.backdropFaint,
          child: Icon(
            Icons.add_outlined,
            color: colorScheme.strokeMuted,
          ),
        ),
      ),
      title: Text(
        AppLocalizations.of(context).newAlbum,
        style: textTheme.body.copyWith(color: colorScheme.textMuted),
      ),
    );
  }
}
