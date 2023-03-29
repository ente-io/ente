import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/subscription.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:ente_auth/services/billing_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:styled_text/styled_text.dart';
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
      future: BillingService.instance.getSubscription(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final subscription = snapshot.data;
          if (subscription != null && subscription.productID != "free") {
            return GestureDetector(
              onTap: () {
                launchUrl(Uri.parse("https://ente.io"));
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6),
                child: Column(
                  children: [
                    StyledText(
                      text: l10n.supportDevs,
                      tags: {
                        'bold-green': StyledTextTag(
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: getEnteColorScheme(context).primaryGreen,
                          ),
                        ),
                      },
                    ),
                    const Padding(padding: EdgeInsets.all(6)),
                    Platform.isAndroid
                        ? Text(
                            l10n.supportDiscount,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
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
