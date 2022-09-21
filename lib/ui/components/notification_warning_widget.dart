import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class NotificationWarningWidget extends StatelessWidget {
  final IconData warningIcon;
  final IconData actionIcon;
  final String text;
  final GestureTapCallback onTap;

  const NotificationWarningWidget({
    Key? key,
    required this.warningIcon,
    required this.actionIcon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(8),
              ),
              boxShadow: Theme.of(context).colorScheme.shadowMenu,
              color: Theme.of(context).colorScheme.warning500,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    warningIcon,
                    size: 36,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      text,
                      style: const TextStyle(height: 1.4, color: Colors.white),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipOval(
                    child: Material(
                      color: Theme.of(context).colorScheme.fillFaint,
                      child: InkWell(
                        splashColor: Colors.red, // Splash color
                        onTap: onTap,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            actionIcon,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
