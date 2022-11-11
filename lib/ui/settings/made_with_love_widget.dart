import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MadeWithLoveWidget extends StatelessWidget {
  const MadeWithLoveWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrl(Uri.parse("https://ente.io"));
      },
      child: RichText(
        text: TextSpan(
          text: "made with ❤️ at ",
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
