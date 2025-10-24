part of 'package:photos/ui/wrapped/wrapped_viewer_page.dart';

typedef _CardContentBuilder = Widget? Function(
  WrappedCard card,
  EnteColorScheme colorScheme,
  EnteTextTheme textTheme,
);

final List<_CardContentBuilder> _cardContentBuilders = <_CardContentBuilder>[
  buildStatsCardContent,
  buildPeopleCardContent,
  buildPlacesCardContent,
  buildAestheticsCardContent,
  buildCurationCardContent,
  buildNarrativeCardContent,
  buildBadgeCardContent,
  buildBadgeDebugCardContent,
];

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
    required this.isActive,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final bool isBadge = card.type == WrappedCardType.badge;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isActive ? 1.0 : 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Material(
          color: isBadge ? Colors.transparent : colorScheme.backgroundElevated,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: isBadge
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: _CardContent(
              card: card,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    for (final _CardContentBuilder builder in _cardContentBuilders) {
      final Widget? built = builder(card, colorScheme, textTheme);
      if (built != null) {
        return built;
      }
    }
    return _GenericCardContent(
      card: card,
      textTheme: textTheme,
    );
  }
}

class _GenericCardContent extends StatelessWidget {
  const _GenericCardContent({
    required this.card,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          style: textTheme.h2Bold,
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              card.subtitle!,
              style: textTheme.bodyMuted,
            ),
          ),
        const Spacer(),
      ],
    );
  }
}
