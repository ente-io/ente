import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';

class DeleteItemsWidget extends StatelessWidget {
  const DeleteItemsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurMuted, sigmaY: blurMuted),
        child: Container(
          color: colorScheme.backdropBase,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextContainer(),
                const SizedBox(height: 36),
                OptionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TextContainer extends StatelessWidget {
  const TextContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Delete items",
          style: textTheme.h3Bold,
        ),
        const SizedBox(height: 19),
        Text(
          "Some items exists both on ente and on your device.",
          style: textTheme.body.copyWith(color: colorScheme.textMuted),
        )
      ],
    );
  }
}

class OptionButtons extends StatelessWidget {
  const OptionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 216,
      width: 303,
      color: Colors.green.shade300.withOpacity(0.5),
    );
  }
}
