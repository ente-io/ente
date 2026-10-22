import "package:ente_components/ente_components.dart";
import "package:ente_strings/ente_strings.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:intl/intl.dart";
import "package:photos/models/backup/backup_item.dart";
import "package:photos/models/backup/backup_item_status.dart";
import "package:photos/ui/settings/backup/backup_item_card.dart";

enum _BackupFilter { all, pending, failed, done }

class BackupStatusView extends StatefulWidget {
  const BackupStatusView({super.key, required this.items});

  final List<BackupItem> items;

  @override
  State<BackupStatusView> createState() => _BackupStatusViewState();
}

class _BackupStatusViewState extends State<BackupStatusView> {
  final _controller = ScrollController();
  _BackupFilter _filter = _BackupFilter.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _BackupFilter _filterFor(BackupItem item) => switch (item.status) {
    BackupItemStatus.uploading ||
    BackupItemStatus.inQueue ||
    BackupItemStatus.inBackground => _BackupFilter.pending,
    BackupItemStatus.retry => _BackupFilter.failed,
    BackupItemStatus.uploaded => _BackupFilter.done,
  };

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colors = context.componentColors;
    final counts = <_BackupFilter, int>{};
    final visibleItems = <BackupItem>[];
    for (final item in widget.items) {
      final category = _filterFor(item);
      counts.update(category, (count) => count + 1, ifAbsent: () => 1);
      if (_filter == _BackupFilter.all || category == _filter) {
        visibleItems.add(item);
      }
    }
    final numberFormat = NumberFormat.decimalPattern(strings.localeName);
    final chipHeight = TagChipComponent.preferredHeight(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: AppBarComponent(
        title: strings.backupStatus,
        controller: _controller,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(chipHeight + Spacing.sm * 2),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                for (final filter in _BackupFilter.values) ...[
                  if (filter != _BackupFilter.all)
                    const SizedBox(width: Spacing.sm),
                  TagChipComponent(
                    label: switch (filter) {
                      _BackupFilter.all => strings.all,
                      _BackupFilter.pending =>
                        "${strings.pending} ${numberFormat.format(counts[filter] ?? 0)}",
                      _BackupFilter.failed =>
                        "${strings.backupStatusFailed} ${numberFormat.format(counts[filter] ?? 0)}",
                      _BackupFilter.done => strings.done,
                    },
                    state: filter == _filter
                        ? TagChipComponentState.selected
                        : TagChipComponentState.unselected,
                    onTap: () {
                      if (_filter == filter) return;
                      setState(() => _filter = filter);
                      _controller.jumpTo(0);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        slivers: [
          if (visibleItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyBackupStatus(
                message: switch (_filter) {
                  _BackupFilter.all ||
                  _BackupFilter.done => strings.backupStatusDescription,
                  _BackupFilter.pending => strings.backupStatusNoPending,
                  _BackupFilter.failed => strings.backupStatusNoFailed,
                },
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.sm,
                Spacing.lg,
                Spacing.lg + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList.builder(
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  final file = item.file;
                  return BackupItemCard(
                    key: ValueKey(
                      file.uploadedFileID != null
                          ? ("uploaded", file.uploadedFileID)
                          : file.localID != null
                          ? ("local", file.localID)
                          : ("generated", file.generatedID),
                    ),
                    item: item,
                    borderRadius: MenuGroupComponent.itemBorderRadius(
                      index: index,
                      itemCount: visibleItems.length,
                    ),
                    showDivider: index < visibleItems.length - 1,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyBackupStatus extends StatelessWidget {
  const _EmptyBackupStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: Spacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCloudUpload,
            color: colors.textLight,
            size: IconSizes.medium,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyles.large.copyWith(color: colors.textLight),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
