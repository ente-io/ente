import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_utils/ente_utils.dart";
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          _LegacyItem(),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _CollectionsItem()),
              SizedBox(width: 8),
              Expanded(child: _TrashItem()),
            ],
          ),
        ],
      ),
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

    return InkWell(
      onTap: () => _openCollections(context),
      borderRadius: borderRadius,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          border: Border.all(
            color: colorScheme.backdropBase,
            width: 1.5,
          ),
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: colorScheme.backgroundElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8.0),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedWallet05,
                color: colorScheme.textBase,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.collections,
                style: textTheme.small,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
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

    return InkWell(
      onTap: () => _openTrash(context),
      borderRadius: borderRadius,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          border: Border.all(
            color: colorScheme.backdropBase,
            width: 1.5,
          ),
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: colorScheme.backgroundElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8.0),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                color: colorScheme.textBase,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.trash,
                style: textTheme.small,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
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

    return InkWell(
      onTap: () => openLegacyPage(context),
      borderRadius: borderRadius,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          border: Border.all(
            color: colorScheme.backdropBase,
            width: 1.5,
          ),
          borderRadius: borderRadius,
        ),
        child: Row(
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary700.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: colorScheme.primary700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.legacy,
                style: textTheme.small,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(
                Icons.chevron_right,
                color: colorScheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
