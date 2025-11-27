import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/trash/trash_service.dart";
import "package:locker/ui/pages/all_collections_page.dart";
import "package:locker/ui/pages/trash_page.dart";

class LegacyCollectionsTrashWidget extends StatelessWidget {
  const LegacyCollectionsTrashWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCollectionsItem(context),
        _buildTrashItem(context),
      ],
    );
  }

  Widget _buildCollectionsItem(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final borderRadius = BorderRadius.circular(20.0);

    return Container(
      margin: const EdgeInsets.only(top: 4.0, bottom: 8.0),
      child: InkWell(
        onTap: () => _openCollections(context),
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(30),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(50),
              width: 0.5,
            ),
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedWallet05,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(70),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.collections,
                  style: textTheme.large.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(60),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrashItem(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final borderRadius = BorderRadius.circular(20.0);

    return Container(
      margin: const EdgeInsets.only(top: 4.0, bottom: 16.0),
      child: InkWell(
        onTap: () => _openTrash(context),
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(30),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(50),
              width: 0.5,
            ),
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedDelete01,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(70),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.trash,
                  style: textTheme.large.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(60),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCollections(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AllCollectionsPage(),
      ),
    );
  }

  Future<void> _openTrash(BuildContext context) async {
    final trashFiles = await TrashService.instance.getTrashFiles();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrashPage(trashFiles: trashFiles),
      ),
    );
  }
}
