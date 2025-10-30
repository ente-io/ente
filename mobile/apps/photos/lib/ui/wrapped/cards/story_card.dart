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

// Boost saturation so blurred backgrounds stay vibrant while we overlay gradients.
const List<double> _kSaturationBoostMatrix = <double>[
  1.27559,
  -0.25032,
  -0.02527,
  0,
  0,
  -0.07441,
  1.09968,
  -0.02527,
  0,
  0,
  -0.07441,
  -0.25032,
  1.32473,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: isBadge
              ? Padding(
                  padding: EdgeInsets.zero,
                  child: _CardContent(
                    card: card,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    _StoryCardBackground(
                      card: card,
                      colorScheme: colorScheme,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.backgroundElevated
                                  .withValues(alpha: 0.45),
                              colorScheme.backgroundElevated
                                  .withValues(alpha: 0.2),
                              colorScheme.backgroundElevated
                                  .withValues(alpha: 0.08),
                            ],
                            stops: const <double>[0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 44, 24, 32),
                      child: _CardContent(
                        card: card,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StoryCardBackground extends StatelessWidget {
  const _StoryCardBackground({
    required this.card,
    required this.colorScheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (card.media.isEmpty) {
      return Container(color: colorScheme.backgroundElevated);
    }
    final MediaRef primary = card.media.first;
    if (primary.uploadedFileID <= 0) {
      return Container(color: colorScheme.backgroundElevated);
    }
    return _BlurredMediaBackground(
      mediaRef: primary,
      colorScheme: colorScheme,
    );
  }
}

class _BlurredMediaBackground extends StatefulWidget {
  const _BlurredMediaBackground({
    required this.mediaRef,
    required this.colorScheme,
  });

  final MediaRef mediaRef;
  final EnteColorScheme colorScheme;

  @override
  State<_BlurredMediaBackground> createState() =>
      _BlurredMediaBackgroundState();
}

class _BlurredMediaBackgroundState extends State<_BlurredMediaBackground> {
  late Future<EnteFile?> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = _loadFile();
  }

  @override
  void didUpdateWidget(covariant _BlurredMediaBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaRef.uploadedFileID != widget.mediaRef.uploadedFileID) {
      _fileFuture = _loadFile();
    }
  }

  Future<EnteFile?> _loadFile() {
    return FilesDB.instance.getAnyUploadedFile(
      widget.mediaRef.uploadedFileID,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EnteFile?>(
      future: _fileFuture,
      builder: (BuildContext context, AsyncSnapshot<EnteFile?> snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: widget.colorScheme.backgroundElevated,
          );
        }
        final EnteFile? file = snapshot.data;
        if (file == null) {
          return Container(
            color: widget.colorScheme.backgroundElevated,
          );
        }
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(_kSaturationBoostMatrix),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                  child: ThumbnailWidget(
                    file,
                    fit: BoxFit.cover,
                    rawThumbnail: true,
                    shouldShowSyncStatus: false,
                    shouldShowArchiveStatus: false,
                    shouldShowPinIcon: false,
                    shouldShowOwnerAvatar: false,
                    shouldShowFavoriteIcon: false,
                    shouldShowVideoDuration: false,
                    shouldShowVideoOverlayIcon: false,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
