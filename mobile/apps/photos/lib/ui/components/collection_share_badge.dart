import "package:ente_icons/ente_icons.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/theme/ente_theme.dart";

const double kCollectionBadgeSize = 20.0;
const double kCollectionBadgeIconSize = 12.0;
const double kCollectionBadgeStrokeWidth = 2.0;
const double kCollectionBadgeBorderWidth = 1.0;

class CollectionStatusBadge extends StatelessWidget {
  static const Color backgroundColor = Color.fromRGBO(255, 255, 255, 0.14);

  final Widget child;

  const CollectionStatusBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kCollectionBadgeSize,
      height: kCollectionBadgeSize,
      decoration: const BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(child: child),
    );
  }
}

class CollectionSelectedBadge extends StatelessWidget {
  const CollectionSelectedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: colorScheme.primary700,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: const HugeIcon(
        icon: HugeIcons.strokeRoundedTick02,
        size: kCollectionBadgeIconSize,
        color: Colors.white,
        strokeWidth: kCollectionBadgeStrokeWidth,
      ),
    );
  }
}

class CollectionFavoriteBadge extends StatelessWidget {
  const CollectionFavoriteBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const CollectionStatusBadge(
      child: Icon(
        EnteIcons.favoriteFilled,
        size: kCollectionBadgeIconSize,
        color: Colors.white,
      ),
    );
  }
}

class CollectionPinnedBadge extends StatelessWidget {
  const CollectionPinnedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const CollectionStatusBadge(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedPin,
        size: kCollectionBadgeIconSize,
        color: Colors.white,
        strokeWidth: kCollectionBadgeStrokeWidth,
      ),
    );
  }
}

class CollectionArchivedBadge extends StatelessWidget {
  const CollectionArchivedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const CollectionStatusBadge(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedArchive03,
        size: kCollectionBadgeIconSize,
        color: Colors.white,
        strokeWidth: kCollectionBadgeStrokeWidth,
      ),
    );
  }
}

class CollectionShareBadge extends StatelessWidget {
  final bool isOutgoing;

  const CollectionShareBadge({
    super.key,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      width: kCollectionBadgeSize,
      height: kCollectionBadgeSize,
      decoration: BoxDecoration(
        color: colorScheme.greenBase,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.fill,
          width: kCollectionBadgeBorderWidth,
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: isOutgoing
              ? HugeIcons.strokeRoundedArrowUpRight01
              : HugeIcons.strokeRoundedArrowDownLeft01,
          strokeWidth: kCollectionBadgeStrokeWidth,
          color: Colors.white,
          size: kCollectionBadgeIconSize,
        ),
      ),
    );
  }
}

class CollectionUnSyncedBadge extends StatelessWidget {
  static const Color _backgroundColor = Color.fromRGBO(242, 72, 34, 1);

  final bool showBorder;

  const CollectionUnSyncedBadge({
    super.key,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      width: kCollectionBadgeSize,
      height: kCollectionBadgeSize,
      decoration: BoxDecoration(
        color: _backgroundColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: colorScheme.fill,
                width: kCollectionBadgeBorderWidth,
              )
            : null,
      ),
      child: const Center(
        child: Icon(
          Icons.cloud_off_outlined,
          size: kCollectionBadgeIconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
