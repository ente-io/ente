// ignore_for_file: public_member_api_docs, sort_constructors_first
import "dart:collection";

import 'package:flutter/material.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/backup_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/backup/backup_item.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/settings/backup/backup_item_card.dart";
import "package:photos/utils/file_uploader.dart";

class BackupStatusScreen extends StatefulWidget {
  const BackupStatusScreen({super.key});

  @override
  State<BackupStatusScreen> createState() => _BackupStatusScreenState();
}

class _BackupStatusScreenState extends State<BackupStatusScreen> {
  LinkedHashMap<String, BackupItem> items = FileUploader.instance.allBackups;

  @override
  void initState() {
    super.initState();

    checkBackupUpdatedEvent();
  }

  void checkBackupUpdatedEvent() {
    Bus.instance.on<BackupUpdatedEvent>().listen((event) {
      items = event.items;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<BackupItem> items = this.items.values.toList();

    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).backupStatus,
            ),
          ),
          items.isEmpty
              ? SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color:
                              Theme.of(context).brightness == Brightness.light
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
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xFF000000).withOpacity(0.7)
                                    : const Color(0xFFFFFFFF).withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (delegateBuildContext, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          primary: false,
                          itemBuilder: (context, index) {
                            return BackupItemCard(item: items[index]);
                          },
                          itemCount: items.length,
                        ),
                      );
                    },
                    childCount: 1,
                  ),
                ),
        ],
      ),
    );
  }
}
