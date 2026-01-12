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
  final Widget? trailingWidget;
  final Alignment stackAlignment;

  const AlbumSharesIcons({
    super.key,
    required this.sharees,
    this.type = AvatarType.sm,
    this.limitCountTo = 2,
    this.removeBorder = true,
    this.trailingWidget,
    this.padding = const EdgeInsets.only(left: 10.0, top: 10, bottom: 10),
    this.stackAlignment = Alignment.topLeft,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = min(sharees.length, limitCountTo);
    final hasMore = sharees.length > limitCountTo;
    final double overlapPadding = getOverlapPadding(type);
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

    if (hasMore) {
      widgets.add(
        Positioned(
          left: (overlapPadding * displayCount),
          child: MoreCountWidget(
            sharees.length - displayCount,
            type: moreCountTypeFromAvatarType(type),
            thumbnailView: removeBorder,
          ),
        ),
      );
    }
    if (trailingWidget != null) {
      widgets.add(
        Positioned(
          left: (overlapPadding * (displayCount + (hasMore ? 1 : 0))) +
              (displayCount > 0 ? 12 : 0),
          child: trailingWidget!,
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Stack(
        alignment: stackAlignment,
        clipBehavior: Clip.none,
        children: widgets,
      ),
    );
  }
}

double getOverlapPadding(AvatarType type) {
  switch (type) {
    case AvatarType.xs:
      return 14.0;
    case AvatarType.sm:
      return 14.0;
    case AvatarType.md:
      return 20.0;
    case AvatarType.lg:
      return 24.0;
    case AvatarType.xl:
      return 28.0;
  }
}

MoreCountType moreCountTypeFromAvatarType(AvatarType type) {
  switch (type) {
    case AvatarType.xs:
      return MoreCountType.xs;
    case AvatarType.sm:
      return MoreCountType.sm;
    case AvatarType.md:
      return MoreCountType.md;
    case AvatarType.lg:
      return MoreCountType.lg;
    case AvatarType.xl:
      return MoreCountType.xl;
  }
}
