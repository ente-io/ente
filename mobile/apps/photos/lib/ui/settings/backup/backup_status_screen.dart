// ignore_for_file: public_member_api_docs, sort_constructors_first
import "dart:async";
import "dart:collection";

import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/backup_updated_event.dart";
import "package:photos/events/file_uploaded_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/backup/backup_item.dart";
import "package:photos/models/backup/backup_item_status.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/settings/backup/backup_item_card.dart";
import "package:photos/utils/file_uploader.dart";

class BackupStatusScreen extends StatefulWidget {
  const BackupStatusScreen({super.key});

  @override
  State<BackupStatusScreen> createState() => _BackupStatusScreenState();
}

class _BackupStatusScreenState extends State<BackupStatusScreen> {
  LinkedHashMap<String, BackupItem> items = FileUploader.instance.allBackups;
  List<BackupItem>? result;
  StreamSubscription? _fileUploadedSubscription;
  StreamSubscription? _backupUpdatedSubscription;

  @override
  void initState() {
    super.initState();

    checkBackupUpdatedEvent();
    getAllFiles();
  }

  Future<void> getAllFiles() async {
    result = (await SearchService.instance.getAllFilesForSearch())
        .where(
          (e) => e.uploadedFileID != null && e.isOwner,
        )
        .map(
          (e) {
            return BackupItem(
              status: BackupItemStatus.uploaded,
              file: e,
              collectionID: e.collectionID ?? 0,
              completer: null,
            );
          },
        )
        .sorted(
          (a, b) => (b.file.uploadedFileID!).compareTo(a.file.uploadedFileID!),
        )
        .toList();
    _fileUploadedSubscription =
        Bus.instance.on<FileUploadedEvent>().listen((event) {
      result!.insert(
        0,
        BackupItem(
          status: BackupItemStatus.uploaded,
          file: event.file,
          collectionID: event.file.collectionID ?? 0,
          completer: null,
        ),
      );
      safeSetState();
    });
    safeSetState();
  }

  void checkBackupUpdatedEvent() {
    _backupUpdatedSubscription =
        Bus.instance.on<BackupUpdatedEvent>().listen((event) {
      items = event.items;
      safeSetState();
    });
  }

  void safeSetState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _fileUploadedSubscription?.cancel();
    _backupUpdatedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<BackupItem> items = this.items.values.toList().sorted(
          (a, b) => a.status.index.compareTo(b.status.index),
        );

    final allItems = <BackupItem>[
      ...items.where(
        (element) => element.status != BackupItemStatus.uploaded,
      ),
      ...?result,
    ];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 32,
        title: TitleWidget(
          title: S.of(context).backupStatus,
          caption: null,
          isTitleH2WithoutLeading: false,
        ),
      ),
      body: allItems.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 60,
                vertical: 12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color.fromRGBO(0, 0, 0, 0.6)
                        : const Color.fromRGBO(255, 255, 255, 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.of(context).backupStatusDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 20 / 16,
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF000000).withValues(alpha: 0.7)
                          : const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            )
          : Scrollbar(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                shrinkWrap: false,
                primary: true,
                prototypeItem: Container(height: 70),
                itemBuilder: (context, index) {
                  return BackupItemCard(
                    item: allItems[index],
                    key: ValueKey(allItems[index].file.uploadedFileID),
                  );
                },
                itemCount: allItems.length,
              ),
            ),
    );
  }
}
