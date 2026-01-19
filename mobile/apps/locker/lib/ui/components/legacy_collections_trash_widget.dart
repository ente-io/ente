import 'package:ente_pure_utils/ente_pure_utils.dart';
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/trash/trash_service.dart";
import "package:locker/ui/pages/all_collections_page.dart";
import "package:locker/ui/pages/trash_page.dart";
import "package:locker/ui/utils/legacy_utils.dart";

class LegacyCollectionsTrashWidget extends StatelessWidget {
  const LegacyCollectionsTrashWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const sectionSpacing = SizedBox(height: 8);

    return const Column(
      children: [
        _LegacyItem(),
        sectionSpacing,
        Row(
          children: [
            Expanded(child: _CollectionsItem()),
            SizedBox(width: 8),
            Expanded(child: _TrashItem()),
          ],
        ),
      ],
    );
  }
}

class _CollectionsItem extends StatelessWidget {
  const _CollectionsItem();

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final borderRadius = BorderRadius.circular(20);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openCollections(context),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedWallet05,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.collections,
                style: textTheme.body,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCollections(BuildContext context) async {
    await routeToPage(context, const AllCollectionsPage());
  }
}

class _TrashItem extends StatelessWidget {
  const _TrashItem();

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final borderRadius = BorderRadius.circular(20);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openTrash(context),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.trash,
                style: textTheme.body,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTrash(BuildContext context) async {
    final trashFiles = await TrashService.instance.getTrashFiles();
    if (!context.mounted) return;
    await routeToPage(context, TrashPage(trashFiles: trashFiles));
  }
}

class _LegacyItem extends StatelessWidget {
  const _LegacyItem();

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final borderRadius = BorderRadius.circular(20);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openLegacyPage(context),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedFavourite,
                  color: colorScheme.primary700,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.legacy,
                style: textTheme.body,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
