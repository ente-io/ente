import 'dart:async';

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/notification_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/user_remote_flag_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/account/verify_recovery_page.dart';
import 'package:photos/ui/components/notification_widget.dart';
import 'package:photos/ui/home/header_error_widget.dart';
import 'package:photos/utils/navigation_util.dart';

const double kContainerHeight = 36;

class ErrorWarningHeader extends StatefulWidget {
  const ErrorWarningHeader({Key? key}) : super(key: key);

  @override
  State<ErrorWarningHeader> createState() => _ErrorWarningHeaderState();
}

class _ErrorWarningHeaderState extends State<ErrorWarningHeader> {
  static final _logger = Logger("StatusBarWidget");

  late StreamSubscription<SyncStatusUpdate> _subscription;
  late StreamSubscription<NotificationEvent> _notificationSubscription;
  bool _showErrorBanner = false;
  Error? _syncError;

  @override
  void initState() {
    super.initState();

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
    });
    _notificationSubscription =
        Bus.instance.on<NotificationEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
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
        _showErrorBanner
            ? Divider(
                height: 8,
                color: getEnteColorScheme(context).strokeFaint,
              )
            : const SizedBox.shrink(),
        _showErrorBanner
            ? HeaderErrorWidget(error: _syncError)
            : const SizedBox.shrink(),
        UserRemoteFlagService.instance.shouldShowRecoveryVerification() &&
                !_showErrorBanner
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
