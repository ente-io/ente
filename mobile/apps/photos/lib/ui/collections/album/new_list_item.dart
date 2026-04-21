import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';

//https://www.figma.com/design/SYtMyLBs5SAOkTbfMMzhqt/Ente-Visual-Design?node-id=39181-172209&t=3qmSZWpXF3ZC4JGN-1

class NewAlbumListItemWidget extends StatelessWidget {
  static const _rowHeight = 68.0;
  static const _cardRadius = 20.0;
  static const _thumbnailSize = 52.0;
  static const _thumbnailRadius = 12.0;
  static const _thumbnailInset = 8.0;
  static const _iconSize = 18.0;

  const NewAlbumListItemWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.fill,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Row(
        children: [
          SizedBox(
            height: _thumbnailSize,
            width: _thumbnailSize,
            child: DottedBorder(
              dashPattern: const [4, 4],
              color: colorScheme.strokeDark,
              strokeWidth: 1,
              padding: EdgeInsets.zero,
              borderType: BorderType.RRect,
              radius: const Radius.circular(_thumbnailRadius),
              child: Container(
                height: _thumbnailSize,
                width: _thumbnailSize,
                decoration: BoxDecoration(
                  color: colorScheme.fill,
                  borderRadius: BorderRadius.circular(_thumbnailRadius),
                ),
                padding: const EdgeInsets.all(_thumbnailInset),
                child: Center(
                  child: SizedBox.square(
                    dimension: _iconSize,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      size: _iconSize,
                      strokeWidth: 1.5,
                      color: colorScheme.contentLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).addNew,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.body.copyWith(color: colorScheme.contentLight),
            ),
          ),
        ],
      ),
    );
  }
}
