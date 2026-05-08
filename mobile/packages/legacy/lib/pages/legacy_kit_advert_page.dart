import "package:ente_legacy/components/gradient_button.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:flutter/material.dart";

const _legacyKitAdvertDescription =
    "Keep your Ente account accessible to people you trust, even if something happens to you.";

const _legacyKitAdvertBullets = [
  "Account recovery is split into 3 parts",
  "Give each part to someone you trust",
  "Any 2 parts can recover your account",
];

Future<bool> showLegacyKitAdvertPage(BuildContext context) async {
  return await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const LegacyKitAdvertPage(),
        ),
      ) ??
      false;
}

class LegacyKitAdvertPage extends StatelessWidget {
  const LegacyKitAdvertPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context, false),
          child: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    _LegacyKitAdvertContent(
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 112),
                    GradientButton(
                      text: "Get started",
                      height: 52,
                      textStyle: textTheme.small.copyWith(height: 20 / 14),
                      onTap: () => Navigator.pop(context, true),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LegacyKitAdvertContent extends StatelessWidget {
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  const _LegacyKitAdvertContent({
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _LegacyKitAdvertIllustration(),
        const SizedBox(height: 24),
        Text(
          "Create a legacy kit",
          textAlign: TextAlign.center,
          style: textTheme.h3Bold.copyWith(
            color: colorScheme.textBase,
            fontSize: 24.0,
            height: 28 / 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _legacyKitAdvertDescription,
          textAlign: TextAlign.center,
          style: textTheme.mini.copyWith(
            color: colorScheme.textMuted,
            height: 16 / 12,
          ),
        ),
        const SizedBox(height: 32),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 279),
          child: Column(
            children: [
              for (var index = 0;
                  index < _legacyKitAdvertBullets.length;
                  index++) ...[
                _LegacyKitAdvertBullet(
                  text: _legacyKitAdvertBullets[index],
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                if (index < _legacyKitAdvertBullets.length - 1)
                  const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LegacyKitAdvertIllustration extends StatelessWidget {
  const _LegacyKitAdvertIllustration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/legacy_kit_advert_foreground.png",
      width: 200,
      height: 116,
      fit: BoxFit.contain,
    );
  }
}

class _LegacyKitAdvertBullet extends StatelessWidget {
  final String text;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  const _LegacyKitAdvertBullet({
    required this.text,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: colorScheme.primary700,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.small.copyWith(
              color: colorScheme.textBase,
              height: 20 / 14,
            ),
          ),
        ),
      ],
    );
  }
}
