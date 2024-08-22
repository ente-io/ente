import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/sync_status_update_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/local_sync_service.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/home/status_bar_widget.dart";
import "package:photos/ui/settings/backup/backup_folder_selection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/photo_manager_util.dart";

class HomeAppBarWidget extends StatefulWidget {
  const HomeAppBarWidget({super.key});

  @override
  State<HomeAppBarWidget> createState() => _HomeAppBarWidgetState();
}

class _HomeAppBarWidgetState extends State<HomeAppBarWidget> {
  bool _showStatus = false;
  bool _showErrorBanner = false;

  late StreamSubscription<SyncStatusUpdate> _subscription;
  final _logger = Logger("HomeAppBarWidget");

  @override
  void initState() {
    super.initState();
    _subscription = Bus.instance.on<SyncStatusUpdate>().listen((event) {
      _logger.info("Received event " + event.status.toString());

      if (event.status == SyncStatus.error) {
        setState(() {
          _showErrorBanner = true;
        });
      } else {
        setState(() {
          _showErrorBanner = false;
        });
      }

      if (event.status == SyncStatus.completedFirstGalleryImport ||
          event.status == SyncStatus.completedBackup) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _showStatus = false;
            });
          }
        });
      } else {
        setState(() {
          _showStatus = true;
        });
      }
    });
  }

  dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  AppBar build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: _showStatus
          ? _showErrorBanner
              ? const Text("ente", style: brandStyleMedium)
              : const SyncStatusWidget()
          : const Text("ente", style: brandStyleMedium),
      actions: [
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
