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
    final List<String> gradient = _stringListFromMeta(card.meta, "gradient");
    final Color primaryColor = gradient.length >= 2
        ? _colorFromHex(gradient.first, colorScheme.primary500)
        : colorScheme.primary500;
    final BoxDecoration decoration = gradient.length >= 2
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: gradient
                  .take(2)
                  .map((String hex) => _colorFromHex(hex, primaryColor))
                  .toList(growable: false),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          )
        : BoxDecoration(
            color: primaryColor,
          );

    return Container(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  card.title,
                  style: textTheme.h1Bold.copyWith(
                    color: Colors.white,
                    height: 1.05,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (card.media.isNotEmpty)
                      _BadgeMediaMosaic(
                        media: card.media,
                        colorScheme: colorScheme,
                      )
                    else
                      _MediaPlaceholder(
                        colorScheme: colorScheme,
                        borderRadius: 20,
                      ),
                    if (card.subtitle != null && card.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          card.subtitle!,
                          textAlign: TextAlign.center,
                          style: textTheme.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeMediaMosaic extends StatelessWidget {
  const _BadgeMediaMosaic({
    required this.media,
    required this.colorScheme,
  });

  final List<MediaRef> media;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final List<MediaRef> items = media.take(9).toList(growable: false);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 12;
        final double maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 320;

        Widget squareTile(MediaRef ref, double size) {
          return SizedBox(
            width: size,
            height: size,
            child: _MediaTile(
              mediaRef: ref,
              borderRadius: 20,
              aspectRatio: 1,
            ),
          );
        }

        if (items.length == 1) {
          final double size = math.min(maxWidth, 220);
          return Center(child: squareTile(items.first, size));
        }

        if (items.length == 2) {
          final double usableWidth = math.max(maxWidth - gap, 0);
          final double size = math.min(usableWidth / 2, 180);
          final double totalWidth = (size * 2) + gap;
          return SizedBox(
            height: size,
            child: Center(
              child: SizedBox(
                width: totalWidth,
                child: Row(
                  children: [
                    squareTile(items[0], size),
                    const SizedBox(width: gap),
                    squareTile(items[1], size),
                  ],
                ),
              ),
            ),
          );
        }

        if (items.length == 3) {
          final double usableWidth = math.max(maxWidth - (gap * 2), 0);
          final double columnWidth = math.min(usableWidth / 3, 140);
          final double largeSize = (columnWidth * 2) + gap;
          final double totalWidth = (columnWidth * 3) + (gap * 2);
          final double height = (columnWidth * 2) + gap;
          return SizedBox(
            height: height,
            child: Center(
              child: SizedBox(
                width: totalWidth,
                height: height,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    squareTile(items[0], largeSize),
                    const SizedBox(width: gap),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        squareTile(items[1], columnWidth),
                        const SizedBox(height: gap),
                        squareTile(items[2], columnWidth),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        const int columns = 3;
        final double tileSize = (maxWidth - gap * (columns - 1)) / columns;
        final int rows = (items.length + columns - 1) ~/ columns;
        final double height =
            (tileSize * rows) + (rows > 1 ? gap * (rows - 1) : 0);
        return SizedBox(
          height: height,
          width: double.infinity,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              childAspectRatio: 1,
            ),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              return _MediaTile(
                mediaRef: items[index],
                borderRadius: 20,
                aspectRatio: 1,
              );
            },
          ),
        );
      },
    );
  }
}

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
