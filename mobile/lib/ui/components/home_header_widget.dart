import "dart:async";
import "dart:io";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/local_sync_service.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/settings/backup/backup_folder_selection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/photo_manager_util.dart";

class HomeHeaderWidget extends StatefulWidget {
  final Widget centerWidget;
  const HomeHeaderWidget({required this.centerWidget, Key? key})
      : super(key: key);

  @override
  State<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends State<HomeHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButtonWidget(
              iconButtonType: IconButtonType.primary,
              icon: Icons.menu_outlined,
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: widget.centerWidget,
        ),
        IconButtonWidget(
          icon: Icons.add_photo_alternate_outlined,
          iconButtonType: IconButtonType.primary,
          onTap: () async {
            try {
              final PermissionState state =
                  await requestPhotoMangerPermissions();
              await LocalSyncService.instance.onUpdatePermission(state);
            } on Exception catch (e) {
              Logger("HomeHeaderWidget").severe(
                "Failed to request permission: ${e.toString()}",
                e,
              );
            }
            if (!LocalSyncService.instance.hasGrantedFullPermission()) {
              if (Platform.isAndroid) {
                await PhotoManager.openSetting();
              } else {
                final bool hasGrantedLimit =
                    LocalSyncService.instance.hasGrantedLimitedPermissions();
                // ignore: unawaited_futures
                showChoiceActionSheet(
                  context,
                  title: S.of(context).preserveMore,
                  body: S.of(context).grantFullAccessPrompt,
                  firstButtonLabel: S.of(context).openSettings,
                  firstButtonOnTap: () async {
                    await PhotoManager.openSetting();
                  },
                  secondButtonLabel: hasGrantedLimit
                      ? S.of(context).selectMorePhotos
                      : S.of(context).cancel,
                  secondButtonOnTap: () async {
                    if (hasGrantedLimit) {
                      await PhotoManager.presentLimited();
                    }
                  },
                );
              }
            } else {
              unawaited(
                routeToPage(
                  context,
                  BackupFolderSelectionPage(
                    buttonText: S.of(context).backup,
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
