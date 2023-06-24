import "dart:math";

import "package:flutter/material.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/ui/sharing/more_count_badge.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";

class AlbumSharesIcons extends StatelessWidget {
  final List<User> sharees;
  final int limitCountTo;
  final AvatarType type;
  final bool removeBorder;
  final EdgeInsets padding;

  const AlbumSharesIcons({
    Key? key,
    required this.sharees,
    this.type = AvatarType.tiny,
    this.limitCountTo = 2,
    this.removeBorder = true,
    this.padding = const EdgeInsets.only(left: 10.0, top: 10, bottom: 10),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayCount = min(sharees.length, limitCountTo);
    final double overlapPadding = type == AvatarType.tiny ? 12.0 : 18.0;
    final widgets = List<Widget>.generate(
      displayCount,
      (index) => Positioned(
        left: overlapPadding * index,
        child: UserAvatarWidget(
          sharees[index],
          thumbnailView: removeBorder,
          type: type,
        ),
      ),
    );

    if (sharees.length > limitCountTo) {
      widgets.add(
        Positioned(
          left: 12.1 * displayCount,
          child: MoreCountWidget(
            sharees.length - displayCount,
            type: MoreCountType.tiny,
            thumbnailView: removeBorder,
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Stack(children: widgets),
    );
  }
}
