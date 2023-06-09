import 'package:flutter/material.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/ui/components/notification_widget.dart";
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/utils/email_util.dart';
import "package:photos/utils/navigation_util.dart";

class HeaderErrorWidget extends StatelessWidget {
  final Error? _error;

  const HeaderErrorWidget({Key? key, required Error? error})
      : _error = error,
        super(key: key);

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
            )
          },
        ),
      );
    } else if (_error is StorageLimitExceededError) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.orange,
                ),
                const Padding(padding: EdgeInsets.all(4)),
                Text(S.of(context).storageLimitExceeded),
              ],
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Container(
              width: 400,
              height: 52,
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
              child: OutlinedButton(
                child: Text(
                  S.of(context).upgrade,
                  style: const TextStyle(height: 1.1),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return getSubscriptionPage();
                      },
                    ),
                  );
                },
              ),
            ),
            const Padding(padding: EdgeInsets.all(12)),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
            ),
            const Padding(padding: EdgeInsets.all(4)),
            Text(
              S.of(context).couldNotBackUpTryLater,
              style: const TextStyle(height: 1.4),
              textAlign: TextAlign.center,
            ),
            const Padding(padding: EdgeInsets.all(8)),
            InkWell(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.inverseTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.fromLTRB(50, 16, 50, 16),
                  side: BorderSide(
                    width: 2,
                    color: Colors.orange[600]!,
                  ),
                ),
                child: Text(
                  S.of(context).raiseTicket,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  sendLogs(
                    context,
                    S.of(context).raiseTicket,
                    "support@ente.io",
                    subject: S.of(context).backupFailed,
                  );
                },
              ),
            ),
            const Padding(padding: EdgeInsets.all(12)),
          ],
        ),
      );
    }
  }
}
