import "dart:io";

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/backup_status.dart';
import 'package:photos/ui/common/gradient_button.dart';
import "package:photos/ui/notification/toast.dart";
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/standalone/data.dart';

class FreeSpacePage extends StatefulWidget {
  final BackupStatus status;
  final bool clearSpaceForFolder;

  const FreeSpacePage(
    this.status, {
    super.key,
    this.clearSpaceForFolder = false,
  });

  @override
  State<FreeSpacePage> createState() => _FreeSpacePageState();
}

class _FreeSpacePageState extends State<FreeSpacePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(S.of(context).freeUpSpace),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    Logger("FreeSpacePage").info(
      "Number of uploaded files: " + widget.status.localIDs.length.toString(),
    );
    Logger("FreeSpacePage")
        .info("Space consumed: " + widget.status.size.toString());
    return SingleChildScrollView(
      child: _getWidget(widget.status),
    );
  }

  Widget _getWidget(BackupStatus status) {
    final count = status.localIDs.length;
    final formattedCount = NumberFormat().format(count);
    final String textMessage = widget.clearSpaceForFolder
        ? S.of(context).filesBackedUpInAlbum(count, formattedCount)
        : S.of(context).filesBackedUpFromDevice(count, formattedCount);
    final informationTextStyle = TextStyle(
      fontSize: 14,
      height: 1.3,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
      fontWeight: FontWeight.w500,
    );
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Stack(
          alignment: Alignment.center,
          children: [
            isLightMode
                ? Image.asset(
                    'assets/loading_photos_background.png',
                    color: Colors.white.withOpacity(0.4),
                    colorBlendMode: BlendMode.modulate,
                  )
                : Image.asset(
                    'assets/loading_photos_background_dark.png',
                    color: Colors.white.withOpacity(0.25),
                  ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Image.asset(
                "assets/gallery_locked.png",
                height: 160,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 36, right: 40),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_done_outlined,
                color: Color.fromRGBO(45, 194, 98, 1.0),
              ),
              const Padding(padding: EdgeInsets.all(10)),
              Expanded(
                child: Text(
                  textMessage,
                  style: informationTextStyle,
                ),
              ),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.all(12)),
        Padding(
          padding: const EdgeInsets.only(left: 36, right: 40),
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                color: Color.fromRGBO(45, 194, 98, 1.0),
              ),
              const Padding(padding: EdgeInsets.all(10)),
              Expanded(
                child: Text(
                  S
                      .of(context)
                      .freeUpSpaceSaving(count, formatBytes(status.size)),
                  style: informationTextStyle,
                ),
              ),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.all(12)),
        Padding(
          padding: const EdgeInsets.only(left: 36, right: 40),
          child: Row(
            children: [
              const Icon(
                Icons.devices,
                color: Color.fromRGBO(45, 194, 98, 1.0),
              ),
              const Padding(padding: EdgeInsets.all(10)),
              Expanded(
                child: Text(
                  S.of(context).freeUpAccessPostDelete(count),
                  style: informationTextStyle,
                ),
              ),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.all(24)),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 64,
          ),
          padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
          child: GradientButton(
            onTap: () async {
              await _freeStorage(status);
            },
            text: S.of(context).freeUpAmount(formatBytes(status.size)),
          ),
        ),
        const Padding(padding: EdgeInsets.all(24)),
      ],
    );
  }

  Future<void> _freeStorage(BackupStatus status) async {
    bool isSuccess = await deleteLocalFiles(context, status.localIDs);

    if (isSuccess == false) {
      isSuccess = await deleteLocalFilesAfterRemovingAlreadyDeletedIDs(
        context,
        status.localIDs,
      );
    }

    if (isSuccess == false && Platform.isAndroid) {
      isSuccess =
          await retryFreeUpSpaceAfterRemovingAssetsNonExistingInDisk(context);
    }

    if (isSuccess) {
      Navigator.of(context).pop(true);
    } else {
      showToast(context, S.of(context).couldNotFreeUpSpace);
    }
  }
}
