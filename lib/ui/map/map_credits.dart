import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class MapCredits extends StatelessWidget {
  const MapCredits({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        child: Text.rich(
          style: const TextStyle(
            fontSize: 11,
          ),
          TextSpan(
            text: 'Map © ',
            children: [
              TextSpan(
                text: 'OpenStreetMap',
                style: const TextStyle(
                  color: Colors.green,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launchUrl(Uri.parse('https://www.openstreetmap.org/'));
                  },
              ),
              const TextSpan(text: ' contributors'),
              const TextSpan(text: ' | Tiles © '),
              TextSpan(
                text: 'HOT',
                style: const TextStyle(
                  color: Colors.green,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launchUrl(Uri.parse('https://www.hotosm.org/'));
                  },
              ),
              const TextSpan(text: ' | Hosted @ '),
              TextSpan(
                text: 'OSM France',
                style: const TextStyle(
                  color: Colors.green,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launchUrl(Uri.parse('https://www.openstreetmap.fr/'));
                  },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
