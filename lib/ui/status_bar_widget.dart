// @dart=2.9

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/notification_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/services/user_remote_flag_service.dart';
import 'package:photos/theme/text_style.dart';
import 'package:photos/ui/account/verify_recovery_page.dart';
import 'package:photos/ui/components/home_header_widget.dart';
import 'package:photos/ui/components/notification_warning_widget.dart';
import 'package:photos/ui/header_error_widget.dart';
import 'package:photos/utils/navigation_util.dart';

const double kContainerHeight = 36;

class StatusBarWidget extends StatefulWidget {
  const StatusBarWidget({Key key}) : super(key: key);

  @override
  State<StatusBarWidget> createState() => _StatusBarWidgetState();
}

class _StatusBarWidgetState extends State<StatusBarWidget> {
  StreamSubscription<SyncStatusUpdate> _subscription;
  StreamSubscription<NotificationEvent> _notificationSubscription;
  bool _showStatus = false;
  bool _showErrorBanner = false;
  Error _syncError;

  @override
  void initState() {
    _subscription = Bus.instance.on<SyncStatusUpdate>().listen((event) {
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
                  : const SyncStatusWidget()
              : const Text("ente", style: brandStyleMedium),
        ),
        AnimatedOpacity(
          opacity: _showErrorBanner ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Divider(
            height: 8,
          ),
        ),
        _showErrorBanner
            ? HeaderErrorWidget(error: _syncError)
            : const SizedBox.shrink(),
        UserRemoteFlagService.instance.shouldShowRecoveryVerification()
            ? NotificationWarningWidget(
                warningIcon: Icons.gpp_maybe,
                actionIcon: Icons.arrow_forward,
                text: "Please ensure you have your 24 word recovery key",
                onTap: () async => {
                  await routeToPage(
                    context,
                    const VerifyRecoveryPage(),
                    forceCustomPageRoute: true,
                  )
                },
              )
            : const SizedBox.shrink()
      ],
    );
  }
}

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({Key key}) : super(key: key);

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  static const Duration kSleepDuration = Duration(milliseconds: 3000);

  SyncStatusUpdate _event;
  StreamSubscription<SyncStatusUpdate> _subscription;

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
        (_event.status == SyncStatus.completedBackup ||
            _event.status == SyncStatus.completedFirstGalleryImport) &&
        (DateTime.now().microsecondsSinceEpoch - _event.timestamp >
            kSleepDuration.inMicroseconds);
    if (_event == null ||
        isNotOutdatedEvent ||
        //sync error cases are handled in StatusBarWidget
        _event.status == SyncStatus.error) {
      return const SizedBox.shrink();
    }
    if (_event.status == SyncStatus.completedBackup) {
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

  final SyncStatusUpdate event;

  const RefreshIndicatorWidget(this.event, {Key key}) : super(key: key);

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
                  child: Text(_getRefreshingText()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRefreshingText() {
    if (event.status == SyncStatus.startedFirstGalleryImport ||
        event.status == SyncStatus.completedFirstGalleryImport) {
      return "Loading gallery...";
    }
    if (event.status == SyncStatus.applyingRemoteDiff) {
      return "Syncing...";
    }
    if (event.status == SyncStatus.preparingForUpload) {
      return "Encrypting backup...";
    }
    if (event.status == SyncStatus.inProgress) {
      return event.completed.toString() +
          "/" +
          event.total.toString() +
          " memories preserved";
    }
    if (event.status == SyncStatus.paused) {
      return event.reason;
    }
    if (event.status == SyncStatus.error) {
      return event.reason ?? "Upload failed";
    }
    if (event.status == SyncStatus.completedBackup) {
      if (event.wasStopped) {
        return "Sync stopped";
      }
    }
    return "All memories preserved";
  }
}

class BrandingWidget extends StatelessWidget {
  const BrandingWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: kContainerHeight,
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "ente",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                fontSize: 24,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SyncStatusCompletedWidget extends StatelessWidget {
  const SyncStatusCompletedWidget({Key key}) : super(key: key);

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
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text("All memories preserved"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
