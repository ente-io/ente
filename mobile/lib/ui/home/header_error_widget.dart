import 'package:flutter/material.dart';
import 'package:photos/core/errors.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/ui/components/notification_widget.dart";
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/utils/email_util.dart';
import "package:photos/utils/navigation_util.dart";

class HeaderErrorWidget extends StatelessWidget {
  final Error? _error;

  const HeaderErrorWidget({super.key, required Error? error})
      : _error = error;

  @override
  Widget build(BuildContext context) {
    if (_error is NoActiveSubscriptionError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        child: NotificationWidget(
          startIcon: Icons.info_rounded,
          actionIcon: Icons.arrow_forward,
          text: S.of(context).subscribe,
          subText: S.of(context).yourSubscriptionHasExpired,
          onTap: () async => {
            await routeToPage(
              context,
              getSubscriptionPage(),
              forceCustomPageRoute: true,
            ),
          },
        ),
      );
    } else if (_error is StorageLimitExceededError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        child: NotificationWidget(
          startIcon: Icons.disc_full_rounded,
          actionIcon: Icons.arrow_forward,
          text: S.of(context).upgrade,
          subText: S.of(context).storageLimitExceeded,
          onTap: () async => {
            await routeToPage(
              context,
              getSubscriptionPage(),
              forceCustomPageRoute: true,
            ),
          },
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        child: NotificationWidget(
          startIcon: Icons.error_outline_rounded,
          actionIcon: Icons.arrow_forward,
          text: S.of(context).backupFailed,
          subText: S.of(context).couldNotBackUpTryLater,
          onTap: () async => {
            sendLogs(
              context,
              S.of(context).raiseTicket,
              "support@ente.io",
              subject: S.of(context).backupFailed,
            ),
          },
        ),
      );
    }
  }
}
