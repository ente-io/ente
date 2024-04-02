import 'package:ente_auth/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MadeWithLoveWidget extends StatelessWidget {
  const MadeWithLoveWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () {
        launchUrl(Uri.parse("https://ente.io"));
      },
      child: RichText(
        text: TextSpan(
          text: l10n.madeWithLoveAtPrefix,
          style: DefaultTextStyle.of(context).style,
          children: const <TextSpan>[
            TextSpan(
              text: 'ente.io',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
