import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

class LegacyKitCreatingPage extends StatelessWidget {
  const LegacyKitCreatingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.backgroundBase,
        appBar: AppBar(
          backgroundColor: colorScheme.backgroundBase,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 48,
          leadingWidth: 48,
          leading: const Icon(Icons.arrow_back_outlined),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Creating your kit",
                style: textTheme.largeBold.copyWith(
                  fontSize: 20.0,
                  height: 28 / 20,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      color: colorScheme.primary700,
                      backgroundColor: colorScheme.isLightTheme
                          ? colorScheme.primary300
                          : colorScheme.fillFaint,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Setting up your legacy kit",
                    textAlign: TextAlign.center,
                    style: textTheme.small.copyWith(
                      color: colorScheme.textMuted,
                      height: 20 / 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
