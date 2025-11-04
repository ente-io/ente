part of 'package:photos/ui/wrapped/wrapped_viewer_page.dart';

Widget? buildBadgeCardContent(
  WrappedCard card,
  EnteColorScheme colorScheme,
  EnteTextTheme textTheme,
) {
  if (card.type != WrappedCardType.badge) {
    return null;
  }
  return _BadgeCardContent(
    card: card,
    colorScheme: colorScheme,
    textTheme: textTheme,
  );
}

class _BadgeCardContent extends StatelessWidget {
  const _BadgeCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final _BadgeVisuals visuals = _badgeVisualsFor(card);
    final _WrappedViewerPageState? viewerState =
        context.findAncestorStateOfType<_WrappedViewerPageState>();
    final GlobalKey? shareKey = viewerState?.shareButtonKey;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardHeight = constraints.maxHeight.isFinite
            ? math.max(constraints.maxHeight, 360)
            : 520;
        final double panelTopUpperBound = math.max(cardHeight - 190.0, 140.0);
        final double panelTop = math.min(
          math.max(cardHeight * 0.30, 110.0),
          panelTopUpperBound,
        );
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360;
        final double artWidth = math.max(math.min(width - 72, 280), 180);
        final double artTopPadding = math.max(panelTop - 140, 4);

        return Container(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 16,
                right: 16,
                top: panelTop,
                bottom: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _kBadgeBaseGreen,
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: panelTop - 80,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.45,
                    child: Image.asset(
                      _BadgeVisualAssets.rays,
                      fit: BoxFit.contain,
                      height: 180,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: panelTop - 48,
                child: IgnorePointer(
                  child: Image.asset(
                    _BadgeVisualAssets.cloud,
                    fit: BoxFit.contain,
                    height: 150,
                    color: Colors.white.withValues(alpha: 0.15),
                    colorBlendMode: BlendMode.srcATop,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: artTopPadding),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: artWidth,
                            ),
                            child: Image.asset(
                              visuals.illustrationAsset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    buildWrappedCardTitle(
                      card.title,
                      textTheme.h2Bold.copyWith(color: Colors.white),
                    ),
                    if (card.subtitle != null && card.subtitle!.isNotEmpty)
                      buildWrappedCardSubtitle(
                        card.subtitle!,
                        textTheme.bodyMuted.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        padding: const EdgeInsets.only(top: 12),
                      ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const _BadgeBrandLogo(),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(left: 14, bottom: 12),
                          child: _BadgeSharePill(
                            labelStyle: textTheme.h3Bold.copyWith(
                              color: _kBadgeBaseGreen,
                              fontSize: 24,
                              height: 1.0,
                            ),
                            onTap: viewerState == null
                                ? null
                                : () =>
                                    unawaited(viewerState.shareCurrentCard()),
                            shareButtonKey: shareKey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BadgeVisuals {
  const _BadgeVisuals({
    required this.illustrationAsset,
  });

  final String illustrationAsset;
}

class _BadgeVisualAssets {
  static const String cloud = "assets/rewind_badges/cloud-effect.png";
  static const String rays = "assets/rewind_badges/rays.png";
  static const String logo = "assets/rewind_badges/simple_logo.png";
  static const String peoplePerson = "assets/rewind_badges/people_person.png";
  static const String consistencyChamp =
      "assets/rewind_badges/consistency_champ.png";
  static const String globetrotter = "assets/rewind_badges/globetrotter.png";
  static const String petParent = "assets/rewind_badges/pet_parent.png";
  static const String minimalist =
      "assets/rewind_badges/minimalist_shooter.png";
  static const String portraitPro = "assets/rewind_badges/portrait_pro.png";
}

const Map<String, String> _kBadgeIllustrations = <String, String>{
  "people_person": _BadgeVisualAssets.peoplePerson,
  "consistency_champ": _BadgeVisualAssets.consistencyChamp,
  "globetrotter": _BadgeVisualAssets.globetrotter,
  "pet_parent": _BadgeVisualAssets.petParent,
  "minimalist_shooter": _BadgeVisualAssets.minimalist,
  "portrait_pro": _BadgeVisualAssets.portraitPro,
};

_BadgeVisuals _badgeVisualsFor(WrappedCard card) {
  final String badgeKey =
      (card.meta["badgeKey"] as String?)?.toLowerCase() ?? "";
  final String asset =
      _kBadgeIllustrations[badgeKey] ?? _BadgeVisualAssets.peoplePerson;
  return _BadgeVisuals(illustrationAsset: asset);
}

class _BadgeBrandLogo extends StatelessWidget {
  const _BadgeBrandLogo();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _kBadgeLogoRotationRadians,
      child: Image.asset(
        _BadgeVisualAssets.logo,
        width: 40,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _BadgeSharePill extends StatelessWidget {
  const _BadgeSharePill({
    required this.labelStyle,
    this.onTap,
    this.shareButtonKey,
  });

  final TextStyle labelStyle;
  final VoidCallback? onTap;
  final GlobalKey? shareButtonKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: shareButtonKey,
        width: 122,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          "Share",
          style: labelStyle,
        ),
      ),
    );
  }
}

const Color _kBadgeBaseGreen = Color(0xFF08C225);
const double _kBadgeLogoRotationRadians = 9.91 * math.pi / 180;

Widget? buildBadgeDebugCardContent(
  WrappedCard card,
  EnteColorScheme colorScheme,
  EnteTextTheme textTheme,
) {
  if (card.type != WrappedCardType.badgeDebug) {
    return null;
  }
  return _BadgeDebugCardContent(
    card: card,
    colorScheme: colorScheme,
    textTheme: textTheme,
  );
}

class _BadgeDebugCardContent extends StatelessWidget {
  const _BadgeDebugCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, Object?>> candidates =
        _mapListFromMeta(card.meta, "candidates");
    if (candidates.isEmpty) {
      return const SizedBox.shrink();
    }
    candidates.sort((Map<String, Object?> a, Map<String, Object?> b) {
      final bool eligibleA = a["eligible"] as bool? ?? false;
      final bool eligibleB = b["eligible"] as bool? ?? false;
      if (eligibleA != eligibleB) {
        return eligibleB ? 1 : -1;
      }
      final double scoreA =
          (a["score"] as num?)?.toDouble() ?? double.negativeInfinity;
      final double scoreB =
          (b["score"] as num?)?.toDouble() ?? double.negativeInfinity;
      final int scoreCompare = scoreB.compareTo(scoreA);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final int tierA = a["tier"] as int? ?? 0;
      final int tierB = b["tier"] as int? ?? 0;
      final int tierCompare = tierA.compareTo(tierB);
      if (tierCompare != 0) {
        return tierCompare;
      }
      final String keyA = a["key"] as String? ?? "";
      final String keyB = b["key"] as String? ?? "";
      return keyA.compareTo(keyB);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Badge candidates (debug)",
          style: textTheme.h2Bold.copyWith(color: colorScheme.fillStrong),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (BuildContext context, int index) {
                return _BadgeCandidateDebugRow(
                  index: index,
                  data: candidates[index],
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeCandidateDebugRow extends StatelessWidget {
  const _BadgeCandidateDebugRow({
    required this.index,
    required this.data,
    required this.colorScheme,
    required this.textTheme,
  });

  final int index;
  final Map<String, Object?> data;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final String name = data["name"] as String? ?? data["key"] as String? ?? "";
    final double? score = (data["score"] as num?)?.toDouble();
    final bool eligible = data["eligible"] as bool? ?? false;
    final int tier = data["tier"] as int? ?? 1;
    final String debugWhy = data["debugWhy"] as String? ?? "";
    final String badgeKey = data["key"] as String? ?? "";

    final TextStyle titleStyle = textTheme.smallBold.copyWith(
      color: eligible ? colorScheme.fillStrong : colorScheme.fillMuted,
    );
    final TextStyle subtitleStyle = textTheme.smallMuted.copyWith(
      color: colorScheme.fillMuted,
    );
    final List<Color> gradientColors =
        _extractGradientColors(data, colorScheme);
    final String? subtitle = data["subtitle"] as String?;
    final String? emoji = data["emoji"] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradientColors.length >= 2
              ? LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: gradientColors.isEmpty ? colorScheme.backgroundElevated : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (emoji != null && emoji.isNotEmpty) ...[
                  Text(
                    emoji,
                    style: textTheme.h2Bold.copyWith(fontSize: 24),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    "${index + 1}. $name",
                    style: titleStyle.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (score != null)
                  Text(
                    score.toStringAsFixed(2),
                    style: titleStyle.copyWith(
                      color: Colors.white,
                      fontFeatures: const <ui.FontFeature>[
                        ui.FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
              ],
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: textTheme.smallMuted.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              "Tier $tier • ${eligible ? "eligible" : "ineligible"} • $badgeKey",
              style: subtitleStyle.copyWith(color: Colors.white70),
            ),
            if (debugWhy.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                debugWhy,
                style: subtitleStyle.copyWith(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<Map<String, Object?>> _mapListFromMeta(
  Map<String, Object?> meta,
  String key,
) {
  final Object? value = meta[key];
  if (value is List) {
    return value
        .whereType<Map>()
        .map(
          (Map raw) => raw.cast<String, Object?>(),
        )
        .toList(growable: false);
  }
  return const <Map<String, Object?>>[];
}

List<Color> _extractGradientColors(
  Map<String, Object?> data,
  EnteColorScheme scheme,
) {
  final Object? raw = data["gradient"];
  if (raw is! List) {
    return <Color>[];
  }
  final List<Color> colors = <Color>[];
  for (final Object? entry in raw) {
    if (entry is String) {
      colors.add(_colorFromHex(entry, scheme.primary500));
    }
  }
  return colors;
}
