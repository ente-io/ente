import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/subscription.dart';
import 'package:ente_auth/services/billing_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportDevWidget extends StatelessWidget {
  const SupportDevWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // fetch
    return FutureBuilder<Subscription>(
      future: BillingService.instance.fetchSubscription(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final subscription = snapshot.data;
          if (subscription != null && subscription.productID == "free") {
            return GestureDetector(
              onTap: () {
                launchUrl(Uri.parse("https://ente.io/download"));
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6),
                child: Text(
                  "${l10n.supportDevs}${Platform.isAndroid ? "\n\n${l10n.supportDiscount}" : ""}",
                  textAlign: TextAlign.center,
                  style: DefaultTextStyle.of(context).style,
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}
