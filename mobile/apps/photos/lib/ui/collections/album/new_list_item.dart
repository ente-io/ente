import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/thumbnail_list_item.dart";

class NewAlbumListItemWidget extends StatelessWidget {
  final Future<void> Function(BuildContext context)? onTap;

  const NewAlbumListItemWidget({
    super.key,
    this.onTap,
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
