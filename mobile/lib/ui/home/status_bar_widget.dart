import 'dart:async';

import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/notification_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/sync_service.dart';
import "package:photos/services/user_remote_flag_service.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/theme/text_style.dart';
import 'package:photos/ui/account/verify_recovery_page.dart';
import 'package:photos/ui/components/home_header_widget.dart';
import 'package:photos/ui/components/notification_widget.dart';
import 'package:photos/ui/home/header_error_widget.dart';
import "package:photos/ui/settings/backup/backup_status_screen.dart";
import "package:photos/ui/settings/ml/enable_ml_consent.dart";
import 'package:photos/utils/navigation_util.dart';

const double kContainerHeight = 36;

class StatusBarWidget extends StatefulWidget {
  const StatusBarWidget({super.key});

  @override
  State<StatusBarWidget> createState() => _StatusBarWidgetState();
}

class _StatusBarWidgetState extends State<StatusBarWidget> {
  static final _logger = Logger("StatusBarWidget");

  late StreamSubscription<SyncStatusUpdate> _subscription;
  late StreamSubscription<NotificationEvent> _notificationSubscription;
  bool _showStatus = false;
  bool _showErrorBanner = false;
  bool _showMlBanner = !userRemoteFlagService
          .getCachedBoolValue(UserRemoteFlagService.mlEnabled) &&
      !localSettings.hasSeenMLEnablingBanner;
  Error? _syncError;

  @override
  void initState() {
    _subscription = Bus.instance.on<SyncStatusUpdate>().listen((event) {
      _logger.info("Received event " + event.status.toString());
      if (event.status == SyncStatus.error) {
        setState(() {
          _syncError = event.error;
          _showErrorBanner = true;
        });
      } else {
        setState(() {
          _syncError = null;
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
    _notificationSubscription =
        Bus.instance.on<NotificationEvent>().listen((event) {
      if (mounted) {
        _showMlBanner = !userRemoteFlagService
                .getCachedBoolValue(UserRemoteFlagService.mlEnabled) &&
            !localSettings.hasSeenMLEnablingBanner;
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _notificationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeHeaderWidget(
          centerWidget: _showStatus
              ? _showErrorBanner
                  ? const Text("ente", style: brandStyleMedium)
                  : GestureDetector(
                      onTap: () {
                        routeToPage(
                          context,
                          const BackupStatusScreen(),
                          forceCustomPageRoute: true,
                        ).ignore();
                      },
                      child: const SyncStatusWidget(),
                    )
              : const Text("ente", style: brandStyleMedium),
        ),
        _showErrorBanner
            ? Divider(
                height: 8,
                color: getEnteColorScheme(context).strokeFaint,
              )
            : const SizedBox.shrink(),
        _showErrorBanner
            ? HeaderErrorWidget(error: _syncError)
            : const SizedBox.shrink(),
        _showMlBanner && !_showErrorBanner
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2.0, vertical: 12),
                child: NotificationWidget(
                  startIcon: Icons.offline_bolt,
                  actionIcon: Icons.arrow_forward,
                  text: S.of(context).enableMachineLearningBanner,
                  type: NotificationType.greenBanner,
                  mainTextStyle: darkTextTheme.smallMuted,
                  onTap: () async => {
                    await routeToPage(
                      context,
                      const EnableMachineLearningConsent(),
                      forceCustomPageRoute: true,
                    ),
                  },
                ),
              )
            : const SizedBox.shrink(),
        userRemoteFlagService.shouldShowRecoveryVerification() &&
                !_showErrorBanner &&
                !_showMlBanner
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: NotificationWidget(
                  startIcon: Icons.error_outline,
                  actionIcon: Icons.arrow_forward,
                  text: S.of(context).confirmYourRecoveryKey,
                  type: NotificationType.banner,
                  onTap: () async => {
                    await routeToPage(
                      context,
                      const VerifyRecoveryPage(),
                      forceCustomPageRoute: true,
                    ),
                  },
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  static const Duration kSleepDuration = Duration(milliseconds: 3000);

  SyncStatusUpdate? _event;
  late StreamSubscription<SyncStatusUpdate> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<SyncStatusUpdate>().listen((event) {
      setState(() {
        _event = event;
      });
    });
    _event = SyncService.instance.getLastSyncStatusEvent();
    super.initState();
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
      return const SyncStatusCompletedWidget();
    }
    return RefreshIndicatorWidget(_event);
  }
}

class RefreshIndicatorWidget extends StatelessWidget {
  static const _inProgressIcon = CircularProgressIndicator(
    strokeWidth: 2,
    valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(45, 194, 98, 1.0)),
  );

  final SyncStatusUpdate? event;

  const RefreshIndicatorWidget(this.event, {super.key});

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
                Container(
                  padding: const EdgeInsets.all(2),
                  width: 22,
                  height: 22,
                  child: _inProgressIcon,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 0, 0),
                  child: Text(_getRefreshingText(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRefreshingText(BuildContext context) {
    if (event == null) {
      return S.of(context).loadingGallery;
    }
    if (event!.status == SyncStatus.startedFirstGalleryImport ||
        event!.status == SyncStatus.completedFirstGalleryImport) {
      return S.of(context).loadingGallery;
    }
    if (event!.status == SyncStatus.applyingRemoteDiff) {
      return S.of(context).syncing;
    }
    if (event!.status == SyncStatus.preparingForUpload) {
      if (event!.total == null || event!.total! <= 0) {
        return S.of(context).encryptingBackup;
      } else if (event!.total == 1) {
        return S.of(context).uploadingSingleMemory;
      } else {
        return S
            .of(context)
            .uploadingMultipleMemories(NumberFormat().format(event!.total!));
      }
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
  const SyncStatusCompletedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.defaultBackgroundColor,
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
                  child: Text(S.of(context).allMemoriesPreserved),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
