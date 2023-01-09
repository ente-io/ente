import 'package:flutter/material.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/utils/email_util.dart';

class HeaderErrorWidget extends StatelessWidget {
  final Error? _error;

  const HeaderErrorWidget({Key? key, required Error? error})
      : _error = error,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (_error is NoActiveSubscriptionError) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Icon(
                  Icons.error_outline,
                  color: Colors.orange,
                ),
                Padding(padding: EdgeInsets.all(4)),
                Text("Your subscription has expired"),
              ],
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Container(
              width: 400,
              height: 52,
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
              child: OutlinedButton(
                child: const Text("Subscribe"),
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
    } else if (_error is StorageLimitExceededError) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Icon(
                  Icons.error_outline,
                  color: Colors.orange,
                ),
                Padding(padding: EdgeInsets.all(4)),
                Text("Storage limit exceeded"),
              ],
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Container(
              width: 400,
              height: 52,
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
              child: OutlinedButton(
                child: const Text(
                  "Upgrade",
                  style: TextStyle(height: 1.1),
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
            const Text(
              "We could not backup your data.\nWe will retry later.",
              style: TextStyle(height: 1.4),
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
                  "Raise ticket",
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
                    "Raise ticket",
                    "support@ente.io",
                    subject: "Backup failed",
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
