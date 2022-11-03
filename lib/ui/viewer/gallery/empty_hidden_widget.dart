import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class EmptyHiddenWidget extends StatelessWidget {
  const EmptyHiddenWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off,
            color: Theme.of(context).iconTheme.color!.withOpacity(0.1),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            "No hidden photos or videos",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .defaultTextColor
                  .withOpacity(0.2),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 36),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EmptyHiddenTextWidget("To hide a photo or video"),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EmptyHiddenTextWidget("• Open the item"),
                    const SizedBox(height: 2),
                    const EmptyHiddenTextWidget(
                      "• Click on the overflow menu",
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          const EmptyHiddenTextWidget("• Click "),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.visibility_off,
                            color: Theme.of(context)
                                .iconTheme
                                .color!
                                .withOpacity(0.7),
                            size: 16,
                          ),
                          const Padding(
                            padding: EdgeInsets.all(4),
                          ),
                          Text(
                            "Hide",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .defaultTextColor
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyHiddenTextWidget extends StatelessWidget {
  final String text;

  const EmptyHiddenTextWidget(
    this.text, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Theme.of(context).colorScheme.defaultTextColor.withOpacity(0.35),
      ),
    );
  }
}
