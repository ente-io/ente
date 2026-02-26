import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';

class EmptyHiddenWidget extends StatelessWidget {
  const EmptyHiddenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final EnteTextTheme enteTextTheme = getEnteTextTheme(context);
    final EnteColorScheme enteColorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off,
              color: enteColorScheme.strokeMuted,
              size: 24,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).noHiddenPhotosOrVideos,
              textAlign: TextAlign.center,
              style: enteTextTheme.body.copyWith(
                color: enteColorScheme.textMuted,
              ),
            ),
            const SizedBox(height: 36),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmptyHiddenTextWidget(
                  AppLocalizations.of(context).toHideAPhotoOrVideo,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EmptyHiddenTextWidget(
                        AppLocalizations.of(context).openTheItem,
                      ),
                      const SizedBox(height: 2),
                      EmptyHiddenTextWidget(
                        AppLocalizations.of(context).clickOnTheOverflowMenu,
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 120,
                        child: Row(
                          children: [
                            EmptyHiddenTextWidget(
                              AppLocalizations.of(context).click,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.visibility_off,
                              color: enteColorScheme.strokeBase,
                              size: 16,
                            ),
                            const Padding(
                              padding: EdgeInsets.all(4),
                            ),
                            Text(
                              AppLocalizations.of(context).hide,
                              style: TextStyle(
                                color: enteColorScheme.textBase,
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
      ),
    );
  }
}

class EmptyHiddenTextWidget extends StatelessWidget {
  final String text;

  const EmptyHiddenTextWidget(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: getEnteColorScheme(context).textFaint,
      ),
    );
  }
}
