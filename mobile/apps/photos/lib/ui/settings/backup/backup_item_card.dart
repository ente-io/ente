import "dart:async";

import "package:ente_components/ente_components.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:ente_strings/ente_strings.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/models/backup/backup_item.dart";
import "package:photos/models/backup/backup_item_status.dart";
import "package:photos/module/upload/service/file_uploader.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/email_util.dart";

class BackupItemCard extends StatefulWidget {
  const BackupItemCard({
    super.key,
    required this.item,
    this.borderRadius = const BorderRadius.all(Radius.circular(Radii.button)),
    this.showDivider = false,
  });

  final BackupItem item;
  final BorderRadius borderRadius;
  final bool showDivider;

  @override
  State<BackupItemCard> createState() => _BackupItemCardState();
}

class _BackupItemCardState extends State<BackupItemCard> {
  bool showThumbnail = false;
  final _logger = Logger("BackupItemCard");

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => showThumbnail = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final strings = context.strings;
    final item = widget.item;
    final statusLabel = switch (item.status) {
      BackupItemStatus.uploading => strings.backupStatusUploading,
      BackupItemStatus.inQueue => strings.queued,
      BackupItemStatus.retry => strings.backupStatusFailed,
      BackupItemStatus.inBackground => strings.backupStatusInBackground,
      BackupItemStatus.uploaded => strings.done,
    };
    final folder = item.file.deviceFolder;
    final percent = item.progressPercent;

    return MenuGroupComponent(
      borderRadius: widget.borderRadius,
      items: [
        MenuComponent(
          title: item.file.displayName,
          subtitle: folder == null || folder.isEmpty
              ? statusLabel
              : "$folder · $statusLabel",
          titleMaxLines: 1,
          subtitleMaxLines: 1,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.sm),
            child: showThumbnail
                ? ThumbnailWidget(item.file, shouldShowSyncStatus: false)
                : ColoredBox(
                    color: colors.strokeFaint,
                    child: const SizedBox.expand(),
                  ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.error != null)
                IconButton(
                  tooltip: strings.backupFailed,
                  icon: Icon(Icons.error_outline, color: colors.warning),
                  onPressed: _showError,
                ),
              switch (item.status) {
                BackupItemStatus.uploading => ExcludeSemantics(
                  child: percent == null
                      ? const SizedBox.shrink()
                      : Text(
                          "$percent%",
                          style: TextStyles.mini.copyWith(
                            color: colors.primary,
                          ),
                        ),
                ),
                BackupItemStatus.uploaded => Icon(
                  Icons.check_rounded,
                  color: colors.primary,
                  size: IconSizes.small,
                ),
                BackupItemStatus.inQueue => Icon(
                  Icons.schedule_rounded,
                  color: colors.textLight,
                  size: IconSizes.small,
                ),
                BackupItemStatus.retry => IconButton(
                  tooltip: strings.retry,
                  icon: Icon(Icons.refresh_rounded, color: colors.warning),
                  onPressed: () async {
                    await FileUploader.instance.upload(
                      item.file,
                      item.collectionID,
                    );
                  },
                ),
                BackupItemStatus.inBackground => SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.textLight,
                  ),
                ),
              },
            ],
          ),
          onTap: () {
            routeToPage(
              context,
              DetailPage(
                DetailPageConfiguration(
                  List.unmodifiable([item.file]),
                  0,
                  "collection",
                ),
              ),
              forceCustomPageRoute: true,
            );
          },
        ),
        if (item.status == BackupItemStatus.uploading)
          Padding(
            padding: const EdgeInsets.only(
              left: 60,
              right: Spacing.md,
              bottom: Spacing.md,
            ),
            child: LinearProgressIndicator(
              value: percent == null
                  ? null
                  : percent == 99
                  ? 0.995
                  : percent / 100,
              minHeight: 2,
              borderRadius: BorderRadius.circular(Radii.xs),
              color: colors.primary,
              backgroundColor: colors.strokeFaint,
              semanticsLabel: statusLabel,
              semanticsValue: percent == null ? null : "$percent%",
            ),
          ),
        if (widget.showDivider)
          const DividerComponent(
            padding: EdgeInsets.only(left: 60, right: Spacing.md),
          ),
      ],
    );
  }

  void _showError() {
    showBottomSheetComponent<void>(
      context: context,
      isDismissible: true,
      builder: (_) => BottomSheetComponent(
        title: context.strings.backupFailed,
        message: context.strings.sorryBackupFailedDesc,
        illustration: Image.asset("assets/warning-grey.png"),
        actions: [
          ButtonComponent(
            label: context.strings.contactSupport,
            onTap: () async {
              _logger.warning(
                "Backup failed for ${widget.item.file.displayName}",
                widget.item.error,
              );
              await sendLogs(
                context,
                context.strings.contactSupport,
                "support@ente.com",
                postShare: () {},
              );
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          ButtonComponent(
            label: context.strings.ok,
            variant: ButtonComponentVariant.secondary,
            onTap: () async {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
