import "dart:typed_data";

import 'package:flutter/material.dart';
import "package:photos/models/backup/backup_item.dart";
import "package:photos/models/backup/backup_item_status.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/utils/file_uploader.dart";
import "package:photos/utils/thumbnail_util.dart";

class BackupItemCard extends StatefulWidget {
  const BackupItemCard({
    super.key,
    required this.item,
  });

  final BackupItem item;

  @override
  State<BackupItemCard> createState() => _BackupItemCardState();
}

class _BackupItemCardState extends State<BackupItemCard> {
  Uint8List? thumbnail;
  String? folderName;

  @override
  void initState() {
    super.initState();
    _getThumbnail();
    _getFolderName();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _getThumbnail() async {
    thumbnail = await getThumbnail(widget.item.file);
    setState(() {});
  }

  _getFolderName() async {
    folderName = widget.item.file.deviceFolder ?? '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF000000).withOpacity(0.08)
              : const Color(0xFFFFFFFF).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: thumbnail != null
                  ? Image.memory(
                      thumbnail!,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.file.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    height: 20 / 16,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF000000)
                        : const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  folderName ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 17 / 14,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color.fromRGBO(0, 0, 0, 0.7)
                        : const Color.fromRGBO(255, 255, 255, 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            width: 48,
            child: Center(
              child: switch (widget.item.status) {
                BackupItemStatus.uploading => SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: colorScheme.primary700,
                    ),
                  ),
                BackupItemStatus.completed => const SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.check,
                      color: Color(0xFF00B33C),
                    ),
                  ),
                BackupItemStatus.inQueue => SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.history,
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color.fromRGBO(0, 0, 0, .6)
                          : const Color.fromRGBO(255, 255, 255, .6),
                    ),
                  ),
                BackupItemStatus.retry => IconButton(
                    icon: const Icon(
                      Icons.sync,
                      color: Color(0xFFFDB816),
                    ),
                    onPressed: () async {
                      await FileUploader.instance.upload(
                        widget.item.file,
                        widget.item.collectionID,
                      );
                    },
                  ),
                BackupItemStatus.inBackground => SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color.fromRGBO(0, 0, 0, .6)
                          : const Color.fromRGBO(255, 255, 255, .6),
                    ),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
