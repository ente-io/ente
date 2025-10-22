part of 'package:photos/ui/wrapped/wrapped_viewer_page.dart';

Widget? buildPeopleCardContent(
  WrappedCard card,
  EnteColorScheme colorScheme,
  EnteTextTheme textTheme,
) {
  switch (card.type) {
    case WrappedCardType.topPerson:
      return _TopPersonCardContent(
        card: card,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
    case WrappedCardType.topThreePeople:
      return _TopThreePeopleCardContent(
        card: card,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
    case WrappedCardType.groupVsSolo:
      return _GroupVsSoloCardContent(
        card: card,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
    case WrappedCardType.newFaces:
      return _NewFacesCardContent(
        card: card,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );
    default:
      return null;
  }
}

class _TopPersonCardContent extends StatelessWidget {
  const _TopPersonCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroMediaCollage(
          media: card.media,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 24),
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
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 20),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _TopThreePeopleCardContent extends StatelessWidget {
  const _TopThreePeopleCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");

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
        if (card.media.isNotEmpty) ...[
          const SizedBox(height: 24),
          _MediaRow(
            media: card.media.take(3).toList(growable: false),
            colorScheme: colorScheme,
          ),
        ],
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 20),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _GroupVsSoloCardContent extends StatelessWidget {
  const _GroupVsSoloCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");

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
        if (card.media.isNotEmpty) ...[
          const SizedBox(height: 20),
          _MediaRow(
            media: card.media.take(3).toList(growable: false),
            colorScheme: colorScheme,
          ),
        ],
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 20),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _NewFacesCardContent extends StatelessWidget {
  const _NewFacesCardContent({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _stringListFromMeta(card.meta, "detailChips");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroMediaCollage(
          media: card.media,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 24),
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
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 20),
          _DetailChips(
            chips: chips,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
        const Spacer(),
      ],
    );
  }
}
