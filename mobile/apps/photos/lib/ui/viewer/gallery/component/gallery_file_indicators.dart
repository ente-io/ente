import "dart:async";

import "package:ente_icons/ente_icons.dart";
import "package:ente_strings/ente_strings.dart";
import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/file_caption_updated_event.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/services/favorites_service.dart";

class GalleryFileIndicators extends StatefulWidget {
  final EnteFile file;
  final int photoGridSize;

  const GalleryFileIndicators({
    required this.file,
    this.photoGridSize = photoGridSizeDefault,
    super.key,
  });

  @override
  State<GalleryFileIndicators> createState() => _GalleryFileIndicatorsState();
}

class _GalleryFileIndicatorsState extends State<GalleryFileIndicators> {
  late final StreamSubscription<FileCaptionUpdatedEvent> _subscription;
  String? _encodedJson;
  bool? _uploaded;
  FileType? _fileType;
  bool _hasCaption = false;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _readMetadata();
    _subscription = Bus.instance.on<FileCaptionUpdatedEvent>().listen((event) {
      if (event.uploadedFileID != widget.file.uploadedFileID) return;
      final hasCaption = event.caption?.trim().isNotEmpty ?? false;
      if (hasCaption != _hasCaption && mounted) {
        setState(() => _hasCaption = hasCaption);
      }
    });
  }

  @override
  void didUpdateWidget(GalleryFileIndicators oldWidget) {
    super.didUpdateWidget(oldWidget);
    _readMetadata(force: !identical(oldWidget.file, widget.file));
  }

  void _readMetadata({bool force = false}) {
    final file = widget.file;
    if (!force &&
        _encodedJson == file.pubMmdEncodedJson &&
        _uploaded == file.isUploaded &&
        _fileType == file.fileType) {
      return;
    }
    _encodedJson = file.pubMmdEncodedJson;
    _uploaded = file.isUploaded;
    _fileType = file.fileType;
    bool hasCaption = false;
    bool isLive = file.fileType == FileType.livePhoto;
    try {
      final metadata = file.pubMagicMetadata;
      hasCaption =
          file.isUploaded && (metadata?.caption?.trim().isNotEmpty ?? false);
      isLive = isLive || (metadata?.mvi ?? 0) > 0;
    } on FormatException {
      // Optional metadata must not prevent a thumbnail from rendering.
    } on TypeError {
      // Ignore unsupported optional metadata.
    }
    _hasCaption = hasCaption;
    _isLive = isLive;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final favorite = FavoritesService.instance.isFavoriteCache(file);
    if (!_hasCaption && !_isLive && !favorite && file.isUploaded) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final size = width >= 96
            ? 18.0
            : width >= 76
            ? 16.0
            : width >= 60
            ? 14.0
            : 12.0;
        final gap = widget.photoGridSize >= 2 && widget.photoGridSize <= 4
            ? 4.0
            : size >= 16
            ? 3.0
            : 2.0;
        final horizontalPadding = size >= 16 ? 4.0 : 3.0;
        final left = <_FooterIcon>[
          if (!file.isUploaded)
            _FooterIcon(
              Icons.cloud_off_outlined,
              size: size,
              semanticLabel: context.strings.notBackedUp,
            ),
          if (favorite)
            _FooterIcon(
              EnteIcons.favoriteFilled,
              size: size,
              semanticLabel: context.strings.favorite,
            ),
          if (_hasCaption)
            _FooterIcon(
              Icons.notes_rounded,
              size: size,
              semanticLabel: context.strings.description,
            ),
        ];
        final leftWidth =
            left.fold<double>(0, (width, icon) => width + icon.width) +
            (left.isEmpty ? 0 : left.length - 1) * gap;
        final leftRow = Row(
          textDirection: TextDirection.ltr,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < left.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              left[i],
            ],
          ],
        );
        final live = Icon(
          Icons.album_outlined,
          size: size,
          color: Colors.white,
          semanticLabel: context.strings.livePhotos,
        );
        final needsTwoRows =
            _isLive &&
            left.length > 1 &&
            width < leftWidth + size + gap + horizontalPadding * 2;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (final corner in [
              if (left.isNotEmpty) Alignment.bottomLeft,
              if (_isLive) Alignment.bottomRight,
            ])
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: corner,
                    end: Alignment.center,
                    colors: const [
                      Color.fromRGBO(0, 0, 0, 0.14),
                      Color.fromRGBO(0, 0, 0, 0.05),
                      Color.fromRGBO(0, 0, 0, 0.0),
                    ],
                    stops: const [0, 0.6, 1],
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 4,
                ),
                child: needsTwoRows
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: leftRow,
                          ),
                          SizedBox(height: gap),
                          Align(alignment: Alignment.centerRight, child: live),
                        ],
                      )
                    : Row(
                        textDirection: TextDirection.ltr,
                        children: [leftRow, const Spacer(), if (_isLive) live],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FooterIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final String semanticLabel;

  const _FooterIcon(
    this.icon, {
    required this.size,
    required this.semanticLabel,
  });

  // Trim blank font side bearings so spacing separates the visible shapes.
  double get _widthFactor => icon == EnteIcons.favoriteFilled
      ? 5 / 6
      : icon == Icons.notes_rounded
      ? .75
      : 1;

  double get width => size * _widthFactor;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Align(
      widthFactor: _widthFactor,
      heightFactor: 1,
      alignment: icon == EnteIcons.favoriteFilled
          ? Alignment.centerLeft
          : Alignment.center,
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
        semanticLabel: semanticLabel,
      ),
    ),
  );
}
