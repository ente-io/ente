import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/sync_status_update_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/local_sync_service.dart";
import "package:photos/services/sync_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/home/error_warning_header_widget.dart";
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
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutQuad,
        switchOutCurve: Curves.easeInQuad,
        child: _showStatus
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutQuad,
                switchOutCurve: Curves.easeInQuad,
                child: _showErrorBanner
                    ? const Text("ente", style: brandStyleMedium)
                    : const SyncStatusWidget(),
              )
            : const Text("ente", style: brandStyleMedium),
      ),
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

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({Key? key}) : super(key: key);

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  static const Duration kSleepDuration = Duration(milliseconds: 3000);

  SyncStatusUpdate? _event;
  late StreamSubscription<SyncStatusUpdate> _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = Bus.instance.on<SyncStatusUpdate>().listen((event) {
      setState(() {
        _event = event;
      });
    });
    _event = SyncService.instance.getLastSyncStatusEvent();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNotOutdatedEvent = _event != null &&
        (_event!.status == SyncStatus.completedBackup ||
            _event!.status == SyncStatus.completedFirstGalleryImport) &&
        (DateTime.now().microsecondsSinceEpoch - _event!.timestamp >
            kSleepDuration.inMicroseconds);
    if (_event == null ||
        isNotOutdatedEvent ||
        //sync error cases are handled in StatusBarWidget
        _event!.status == SyncStatus.error) {
      return const SizedBox.shrink();
    }
    if (_event!.status == SyncStatus.completedBackup) {
      return const AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutQuad,
        switchOutCurve: Curves.easeInQuad,
        child: SyncStatusCompletedWidget(),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutQuad,
      switchOutCurve: Curves.easeInQuad,
      child: RefreshIndicatorWidget(_event),
    );
  }
}

class RefreshIndicatorWidget extends StatelessWidget {
  final SyncStatusUpdate? event;

  const RefreshIndicatorWidget(this.event, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kContainerHeight,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                EnteLoadingWidget(
                  color: getEnteColorScheme(context).primary400,
                ),
                const SizedBox(width: 12),
                Text(
                  _getRefreshingText(context),
                  style: getEnteTextTheme(context).small,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRefreshingText(BuildContext context) {
    if (event!.status == SyncStatus.startedFirstGalleryImport ||
        event!.status == SyncStatus.completedFirstGalleryImport) {
      return S.of(context).loadingGallery;
    }
    if (event!.status == SyncStatus.applyingRemoteDiff) {
      return S.of(context).syncing;
    }
    if (event!.status == SyncStatus.preparingForUpload) {
      return S.of(context).encryptingBackup;
    }
    if (event!.status == SyncStatus.inProgress) {
      final format = NumberFormat();
      return S.of(context).syncProgress(
            format.format(event!.completed!),
            format.format(event!.total!),
          );
    }
    if (event!.status == SyncStatus.paused) {
      return event!.reason;
    }
    if (event!.status == SyncStatus.error) {
      return event!.reason;
    }
    if (event!.status == SyncStatus.completedBackup) {
      if (event!.wasStopped) {
        return S.of(context).syncStopped;
      }
    }
    return S.of(context).allMemoriesPreserved;
  }
}

class SyncStatusCompletedWidget extends StatelessWidget {
  const SyncStatusCompletedWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      color: colorScheme.backdropBase,
      height: kContainerHeight,
      child: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  color: Theme.of(context).colorScheme.greenAlternative,
                  size: 22,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    S.of(context).allMemoriesPreserved,
                    style: getEnteTextTheme(context).small,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
