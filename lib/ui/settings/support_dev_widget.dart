import 'package:dotted_border/dotted_border.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/subscription.dart';
import 'package:ente_auth/services/billing_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:styled_text/styled_text.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportDevWidget extends StatelessWidget {
  const SupportDevWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // fetch
    if (Configuration.instance.hasConfiguredAccount()) {
      return FutureBuilder<Subscription>(
        future: BillingService.instance.getSubscription(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final subscription = snapshot.data;
            if (subscription != null && subscription.productID == "free") {
              return buildWidget(l10n, context);
            }
          }
          return const SizedBox.shrink();
        },
      );
    } else {
      return buildWidget(l10n, context);
    }
  }

  Widget buildWidget(AppLocalizations l10n, BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrl(Uri.parse("https://ente.io"));
      },
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        padding: const EdgeInsets.all(6),
        dashPattern: const <double>[3, 3],
        color: getEnteColorScheme(context).primaryGreen,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StyledText(
                  text: l10n.supportDevs,
                  style: getEnteTextTheme(context).large,
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
                Text(
                  l10n.supportDiscount,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
