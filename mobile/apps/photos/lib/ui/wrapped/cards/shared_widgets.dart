part of 'package:photos/ui/wrapped/wrapped_viewer_page.dart';

class _DetailChips extends StatelessWidget {
  const _DetailChips({
    required this.chips,
    required this.colorScheme,
    required this.textTheme,
  });

  final List<String> chips;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: chips
          .map(
            (String chip) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.fillFaint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                chip,
                style: textTheme.smallMuted.copyWith(
                  color: textTheme.smallMuted.color ?? colorScheme.fillMuted,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _HeroMediaCollage extends StatelessWidget {
  const _HeroMediaCollage({
    required this.media,
    required this.colorScheme,
  });

  final List<MediaRef> media;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return _MediaPlaceholder(
        height: 220,
        colorScheme: colorScheme,
        borderRadius: 24,
      );
    }

    final List<MediaRef> trimmed = media.take(3).toList(growable: false);
    final MediaRef primary = trimmed.first;
    final List<MediaRef> side = trimmed.skip(1).toList(growable: false);

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _MediaTile(
              mediaRef: primary,
              borderRadius: 24,
              aspectRatio: 3 / 4,
            ),
          ),
          if (side.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: List<Widget>.generate(
                  2,
                  (int index) {
                    final MediaRef? ref =
                        index < side.length ? side[index] : null;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: index == 0 ? 12 : 0,
                        ),
                        child: ref != null
                            ? _MediaTile(
                                mediaRef: ref,
                                borderRadius: 20,
                              )
                            : _MediaPlaceholder(
                                colorScheme: colorScheme,
                                borderRadius: 20,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({
    required this.media,
    required this.colorScheme,
  });

  final List<MediaRef> media;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Row(
        children: [
          for (final (int index, MediaRef ref) in media.indexed) ...[
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: index == media.length - 1 ? 0 : 12),
                child: _MediaTile(
                  mediaRef: ref,
                  borderRadius: 18,
                ),
              ),
            ),
          ],
          if (media.isEmpty)
            Expanded(
              child: _MediaPlaceholder(
                colorScheme: colorScheme,
                borderRadius: 18,
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.media,
    required this.colorScheme,
  });

  final List<MediaRef> media;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return _MediaPlaceholder(
        height: 200,
        colorScheme: colorScheme,
      );
    }
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: Column(
        children: List<Widget>.generate(3, (int row) {
          return Expanded(
            child: Row(
              children: List<Widget>.generate(2, (int column) {
                final int index = row * 2 + column;
                final MediaRef? ref =
                    index < media.length ? media[index] : null;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: column == 1 ? 0 : 10,
                      bottom: row == 2 ? 0 : 10,
                    ),
                    child: ref != null
                        ? _MediaTile(
                            mediaRef: ref,
                            borderRadius: 16,
                          )
                        : _MediaPlaceholder(
                            colorScheme: colorScheme,
                            borderRadius: 16,
                          ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.mediaRef,
    required this.borderRadius,
    this.aspectRatio,
  });

  final MediaRef mediaRef;
  final double borderRadius;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox.expand(
        child: _MediaThumb(
          ref: mediaRef,
        ),
      ),
    );
    if (aspectRatio != null) {
      content = AspectRatio(
        aspectRatio: aspectRatio!,
        child: content,
      );
    }
    return content;
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({
    required this.colorScheme,
    this.height,
    this.borderRadius = 20,
  });

  final EnteColorScheme colorScheme;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget child = Container(
      decoration: BoxDecoration(
        color: colorScheme.primary400.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
    if (height != null) {
      return SizedBox(
        height: height,
        child: child,
      );
    }
    return child;
  }
}

class _MediaThumb extends StatefulWidget {
  const _MediaThumb({required this.ref});

  final MediaRef ref;

  @override
  State<_MediaThumb> createState() => _MediaThumbState();
}

class _MediaThumbState extends State<_MediaThumb> {
  late Future<EnteFile?> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = FilesDB.instance.getAnyUploadedFile(
      widget.ref.uploadedFileID,
    );
  }

  @override
  void didUpdateWidget(covariant _MediaThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ref.uploadedFileID != widget.ref.uploadedFileID) {
      _fileFuture = FilesDB.instance.getAnyUploadedFile(
        widget.ref.uploadedFileID,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return FutureBuilder<EnteFile?>(
      future: _fileFuture,
      builder: (BuildContext context, AsyncSnapshot<EnteFile?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: colorScheme.fillFaint,
          );
        }
        final EnteFile? file = snapshot.data;
        if (file == null) {
          return Container(
            color: colorScheme.fillFaint,
          );
        }
        return ThumbnailWidget(
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
        );
      },
    );
  }
}

Color _heatmapColorForValue(
  int value,
  int maxValue,
  EnteColorScheme scheme,
) {
  if (value <= 0 || maxValue <= 0) {
    return scheme.fillFaint;
  }
  final double t = (value / maxValue).clamp(0.0, 1.0);
  return Color.lerp(
        scheme.primary400.withValues(alpha: 0.25),
        scheme.primary500,
        t,
      ) ??
      scheme.primary500;
}

List<String> _stringListFromMeta(
  Map<String, Object?> meta,
  String key,
) {
  final Object? raw = meta[key];
  if (raw is List) {
    return raw.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}

class _StoryProgressBar extends StatelessWidget {
  const _StoryProgressBar({
    required this.progressValues,
    required this.colorScheme,
  });

  final List<double> progressValues;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final Color trackColor = Colors.white.withValues(alpha: 0.22);
    final Color fillColor = Colors.white.withValues(alpha: 0.92);
    return Row(
      children: [
        for (final (int index, double value)
            in progressValues.indexed) ...<Widget>[
          Expanded(
            child: _ProgressSegment(
              progress: value,
              trackColor: trackColor,
              fillColor: fillColor,
            ),
          ),
          if (index != progressValues.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(
            height: 4,
            color: trackColor,
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              height: 4,
              color: fillColor,
            ),
          ),
        ],
      ),
    );
  }
}
