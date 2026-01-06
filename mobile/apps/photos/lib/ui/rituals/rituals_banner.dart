import "dart:async";
import "dart:math" as math;

import "package:ente_icons/ente_icons.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/rituals/ritual_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/rituals/all_rituals_screen.dart";
import "package:photos/ui/rituals/ritual_camera_page.dart";
import "package:photos/ui/rituals/ritual_editor_dialog.dart";
import "package:photos/ui/rituals/ritual_emoji_icon.dart";
import "package:photos/ui/rituals/ritual_page.dart";
import "package:photos/ui/rituals/start_new_ritual_card.dart";
import "package:photos/utils/navigation_util.dart";

class RitualsBanner extends StatelessWidget {
  const RitualsBanner({super.key});

  static const _cardRadius = 25.0;
  static const _cardHeight = 100.0;
  static const _cardWidth = 180.0;

  @override
  Widget build(BuildContext context) {
    if (!flagService.ritualsFlag) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<RitualsState>(
      valueListenable: ritualsService.stateNotifier,
      builder: (context, state, _) {
        final rituals = state.rituals;
        final summary = state.summary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RitualsHeader(
              showChevron: rituals.isNotEmpty,
              onTap: rituals.isNotEmpty
                  ? () => routeToPage(context, const AllRitualsScreen())
                  : null,
            ),
            const SizedBox(height: 2),
            if (rituals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StartNewRitualCard(
                  variant: StartNewRitualCardVariant.wide,
                  onTap: () async {
                    await _openNewRitualFromSearchTab(context);
                  },
                ),
              )
            else
              SizedBox(
                height: _cardHeight,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (index, item)
                          in _buildRowItems(context, rituals, summary)
                              .indexed) ...[
                        if (index != 0) const SizedBox(width: 10),
                        item,
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openNewRitualFlow(BuildContext context) {
    routeToPage(context, const AllRitualsScreen());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await showRitualEditor(context, ritual: null);
    });
  }

  Future<void> _openNewRitualFromSearchTab(BuildContext context) async {
    final existingRitualIds = ritualsService.stateNotifier.value.rituals
        .map((ritual) => ritual.id)
        .toSet();
    await showRitualEditor(context, ritual: null);
    if (!context.mounted) return;

    Ritual? createdRitual;
    for (final ritual in ritualsService.stateNotifier.value.rituals) {
      if (!existingRitualIds.contains(ritual.id)) {
        createdRitual = ritual;
        break;
      }
    }
    if (createdRitual == null) return;
    unawaited(
      routeToPage(
        context,
        RitualPage(ritualId: createdRitual.id),
      ),
    );
  }

  List<Widget> _buildRowItems(
    BuildContext context,
    List<Ritual> rituals,
    RitualsSummary? summary,
  ) {
    return [
      for (final ritual in rituals)
        _RitualSummaryCard(
          ritual: ritual,
          progress: summary?.ritualProgress[ritual.id],
        ),
      if (rituals.isNotEmpty)
        StartNewRitualCard(
          variant: StartNewRitualCardVariant.compact,
          onTap: () => _openNewRitualFlow(context),
        ),
    ];
  }
}

class _RitualsHeader extends StatelessWidget {
  const _RitualsHeader({
    required this.showChevron,
    required this.onTap,
  });

  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              context.l10n.ritualsTitle,
              style: textTheme.largeBold,
            ),
          ),
          if (showChevron)
            Container(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
                child: Icon(
                  Icons.chevron_right_outlined,
                  color: colorScheme.blurStrokePressed,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RitualSummaryCard extends StatelessWidget {
  const _RitualSummaryCard({
    required this.ritual,
    required this.progress,
  });

  final Ritual ritual;
  final RitualProgress? progress;

  static const _cardRadius = RitualsBanner._cardRadius;
  static const _cardHeight = RitualsBanner._cardHeight;
  static const _cardWidth = RitualsBanner._cardWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? colorScheme.backgroundElevated2
        : const Color(0xFFFAFAFA);
    final streak = progress?.currentStreak ?? 0;

    return SizedBox(
      width: _cardWidth,
      height: _cardHeight,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(_cardRadius),
          onTap: () {
            routeToPage(
              context,
              RitualPage(ritualId: ritual.id),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _RitualIcon(ritual: ritual),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ritual.title.isEmpty
                            ? context.l10n.ritualUntitled
                            : ritual.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.miniBold,
                        textHeightBehavior: _tightTextHeightBehavior,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _StreakIndicator(streak: streak, isDark: isDark),
                    const Spacer(),
                    _RitualCameraButton(
                      onTap: () => openRitualCamera(context, ritual),
                      tooltip: context.l10n.ritualOpenCameraTooltip,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RitualIcon extends StatelessWidget {
  const _RitualIcon({required this.ritual});

  final Ritual ritual;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: RitualEmojiIcon(
          ritual.icon,
          style: textTheme.bodyBold.copyWith(height: 1),
          textHeightBehavior: _tightTextHeightBehavior,
        ),
      ),
    );
  }
}

class _StreakIndicator extends StatelessWidget {
  const _StreakIndicator({
    required this.streak,
    required this.isDark,
  });

  final int streak;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StreakNumber(streak: streak, isDark: isDark),
        const SizedBox(width: 4),
        const _LightningIcon(),
      ],
    );
  }
}

class _StreakNumber extends StatelessWidget {
  const _StreakNumber({
    required this.streak,
    required this.isDark,
  });

  final int streak;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final text = streak.toString();
    const style = TextStyle(
      fontFamily: "Nunito",
      fontSize: 24,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.96,
      height: 1,
    );

    if (isDark) {
      return Text(
        text,
        style: style.copyWith(color: colorScheme.textBase),
        textHeightBehavior: _tightTextHeightBehavior,
      );
    }

    final gradient = _linearGradientFromCssAngle(
      degrees: 178,
      colors: const [
        Color(0xFF545454),
        Color(0xFF000000),
      ],
      stops: const [0.1192, 0.8251],
    );

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        ExcludeSemantics(
          child: Text(
            text,
            style: style.copyWith(
              color: Colors.transparent,
              shadows: [
                Shadow(
                  offset: const Offset(0, 5),
                  blurRadius: 3.3,
                  color: Colors.black.withValues(alpha: 0.07),
                ),
              ],
            ),
            textHeightBehavior: _tightTextHeightBehavior,
          ),
        ),
        _GradientText(
          text,
          gradient: gradient,
          style: style,
          textHeightBehavior: _tightTextHeightBehavior,
        ),
      ],
    );
  }
}

class _LightningIcon extends StatelessWidget {
  const _LightningIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 17,
      child: Center(
        child: Icon(
          EnteIcons.lightningFilled,
          size: 17,
          color: Color(0xFFFFBC03),
        ),
      ),
    );
  }
}

class _RitualCameraButton extends StatelessWidget {
  const _RitualCameraButton({
    required this.onTap,
    required this.tooltip,
  });

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? colorScheme.strokeFaint : Colors.black.withValues(alpha: 0.04);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.backgroundElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCamera01,
                size: 18,
                color: colorScheme.textBase,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _tightTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

class _GradientText extends StatelessWidget {
  const _GradientText(
    this.text, {
    required this.gradient,
    required this.style,
    this.textHeightBehavior,
  });

  final String text;
  final Gradient gradient;
  final TextStyle style;
  final TextHeightBehavior? textHeightBehavior;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
        textHeightBehavior: textHeightBehavior,
      ),
    );
  }
}

LinearGradient _linearGradientFromCssAngle({
  required double degrees,
  required List<Color> colors,
  List<double>? stops,
}) {
  final radians = degrees * math.pi / 180;
  final dx = math.sin(radians);
  final dy = -math.cos(radians);
  return LinearGradient(
    begin: Alignment(-dx, -dy),
    end: Alignment(dx, dy),
    colors: colors,
    stops: stops,
  );
}
