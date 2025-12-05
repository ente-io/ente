import "dart:io";
import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/share_util.dart";
import "package:share_plus/share_plus.dart";

const Color _badgeGreen = Color(0xFF08C225);

const Map<int, String> _badgeAssets = {
  7: "assets/rituals/7_badge.png",
  14: "assets/rituals/14_badge.png",
  30: "assets/rituals/30_badge.png",
};

List<Color> _headingGradientColors(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  return brightness == Brightness.dark
      ? [
          Colors.white.withValues(alpha: 0.92),
          Colors.white.withValues(alpha: 0.72),
        ]
      : const [
          Color(0xFF545454),
          Colors.black,
        ];
}

Color _raysColor(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  return brightness == Brightness.dark
      ? _badgeGreen.withValues(alpha: 0.82)
      : _badgeGreen.withValues(alpha: 1.0);
}

String _badgeMessage(BuildContext context, int days) {
  switch (days) {
    case 7:
      return context.l10n.ritualBadgeMessage7;
    case 14:
      return context.l10n.ritualBadgeMessage14;
    case 30:
      return context.l10n.ritualBadgeMessage30;
    default:
      return context.l10n.ritualBadgeMessageDefault;
  }
}

final Logger _logger = Logger("RitualBadgePopup");

Future<void> showRitualBadgePopup(
  BuildContext context, {
  required RitualBadgeUnlock badge,
  bool allowShare = true,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _RitualBadgePopupSheet(
      badge: badge,
      allowShare: allowShare,
    ),
  );
}

class _RitualBadgePopupSheet extends StatefulWidget {
  const _RitualBadgePopupSheet({
    required this.badge,
    required this.allowShare,
  });

  final RitualBadgeUnlock badge;
  final bool allowShare;

  @override
  State<_RitualBadgePopupSheet> createState() => _RitualBadgePopupSheetState();
}

class _RitualBadgePopupSheetState extends State<_RitualBadgePopupSheet> {
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = context.l10n;
    final headingGradientColors = _headingGradientColors(context);
    final raysColor = _raysColor(context);
    final badgeAsset = _badgeAssets[widget.badge.days] ?? _badgeAssets[7]!;
    final badgeMessage = _badgeMessage(context, widget.badge.days);
    final title = widget.badge.ritual.title.isEmpty
        ? l10n.ritualUntitled
        : widget.badge.ritual.title;
    final double bottomPadding =
        16 + mediaQuery.padding.bottom.clamp(0.0, 16.0).toDouble();

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox.expand(),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: mediaQuery.viewInsets.bottom,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: colorScheme.backgroundElevated,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                border: Border.all(
                  color: colorScheme.strokeFaint,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.fillFaint,
                        padding: const EdgeInsets.all(8),
                        shape: const CircleBorder(),
                        minimumSize: const Size(40, 40),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.textBase,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.center,
                        child: SizedOverflowBox(
                          size: ui.Size.zero,
                          alignment: Alignment.center,
                          // The SVG bounds include large transparent top/bottom; mask them
                          // out while keeping the fidgets centered behind the badge.
                          child: Transform.translate(
                            offset: const Offset(0, -80),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) =>
                                  const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0, 0.16, 0.84, 1],
                                colors: [
                                  Colors.transparent,
                                  Colors.white,
                                  Colors.white,
                                  Colors.transparent,
                                ],
                              ).createShader(bounds),
                              blendMode: BlendMode.dstIn,
                              child: SvgPicture.asset(
                                "assets/rituals/badge_popup_fidgets.svg",
                                fit: BoxFit.cover,
                                width: 220,
                                height: 220,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback: (Rect bounds) => LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.2933, 1],
                            colors: headingGradientColors,
                          ).createShader(
                            Rect.fromLTWH(
                              0,
                              0,
                              bounds.width,
                              bounds.height,
                            ),
                          ),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            l10n.ritualBadgeNewTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: "Nunito",
                              fontStyle: FontStyle.normal,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.72,
                              height: 1.15,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SvgPicture.asset(
                          "assets/rituals/green_stroke.svg",
                          width: 74,
                          height: 8,
                        ),
                        const SizedBox(height: 14),
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 240,
                              child: OverflowBox(
                                maxWidth: 900,
                                maxHeight: 900,
                                child: Transform.translate(
                                  offset: const Offset(0, -100),
                                  child: SvgPicture.asset(
                                    "assets/rituals/background_rays.svg",
                                    width: 900,
                                    height: 900,
                                    fit: BoxFit.contain,
                                    colorFilter: ColorFilter.mode(
                                      raysColor,
                                      BlendMode.srcATop,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Image.asset(
                              badgeAsset,
                              width: 184,
                              height: 184,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        _RitualChip(
                          icon: widget.badge.ritual.icon.isEmpty
                              ? "📸"
                              : widget.badge.ritual.icon,
                          title: title,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          badgeMessage,
                          textAlign: TextAlign.center,
                          style: textTheme.body.copyWith(
                            fontSize: 18,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 36),
                        if (widget.allowShare)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              key: _shareButtonKey,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: _sharing
                                  ? null
                                  : () async {
                                      setState(() {
                                        _sharing = true;
                                      });
                                      try {
                                        await shareRitualBadge(
                                          context,
                                          badge: widget.badge,
                                          shareButtonKey: _shareButtonKey,
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _sharing = false;
                                          });
                                        }
                                      }
                                    },
                              child: Text(
                                _sharing
                                    ? l10n.ritualBadgePreparing
                                    : l10n.share,
                                style: textTheme.bodyBold.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RitualChip extends StatelessWidget {
  const _RitualChip({
    required this.icon,
    required this.title,
    this.useDarkTheme = false,
  });

  final String icon;
  final String title;
  final bool useDarkTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        useDarkTheme ? darkTheme.colorScheme : getEnteColorScheme(context);
    final textTheme =
        useDarkTheme ? darkTheme.textTheme : getEnteTextTheme(context);
    final brightness =
        useDarkTheme ? Brightness.dark : Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? colorScheme.backgroundElevated2
            : Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _badgeGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: _badgeGreen.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _badgeGreen,
              child: Text(
                icon,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: textTheme.bodyBold,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> shareRitualBadge(
  BuildContext context, {
  required RitualBadgeUnlock badge,
  GlobalKey? shareButtonKey,
}) async {
  OverlayEntry? entry;
  try {
    final badgeAsset = _badgeAssets[badge.days] ?? _badgeAssets[7]!;
    await _precacheBadgeAssets(badgeAsset, context);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      throw StateError("Overlay not available for badge share");
    }
    final repaintKey = GlobalKey();
    entry = OverlayEntry(
      builder: (_) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: IgnorePointer(
            child: Opacity(
              // Keep the share card invisible while still allowing it to paint.
              opacity: 0.01,
              child: RepaintBoundary(
                key: repaintKey,
                child: _RitualBadgeShareCard(badge: badge),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    final boundary = await _waitForBoundaryReady(repaintKey: repaintKey);
    final double pixelRatio =
        (MediaQuery.of(context).devicePixelRatio * 1.8).clamp(2.4, 3.5);
    late final ui.Image image;
    try {
      image = await boundary.toImage(pixelRatio: pixelRatio);
    } catch (e, s) {
      _logger.warning("Badge share toImage failed", e, s);
      rethrow;
    }
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png).catchError(
      (Object e, StackTrace s) {
        _logger.warning("Badge share toByteData failed", e, s);
        throw e;
      },
    );
    final data = byteData?.buffer.asUint8List();
    if (data == null || data.isEmpty) {
      throw StateError("Unable to encode badge image");
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      "${dir.path}/ritual_badge_${badge.days}_${badge.ritual.id}_${DateTime.now().millisecondsSinceEpoch}.png",
    );
    await file.writeAsBytes(data, flush: true);
    _logger.info(
      "Sharing ritual badge for ${badge.ritual.id} (${badge.days}d); file: ${file.path}",
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        sharePositionOrigin: shareButtonRect(context, shareButtonKey),
      ),
    );
  } catch (e, s) {
    _logger.warning("Failed to share ritual badge", e, s);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.ritualShareUnavailable),
        ),
      );
    }
  } finally {
    entry?.remove();
  }
}

Future<void> _precacheBadgeAssets(
  String badgeAsset,
  BuildContext context,
) async {
  final providers = <ImageProvider>[
    AssetImage(badgeAsset),
    const AssetImage("assets/qr_logo.png"),
    const AssetImage("assets/ente_io_green.png"),
  ];
  for (final provider in providers) {
    try {
      await precacheImage(provider, context);
    } catch (e, s) {
      _logger.fine("Failed to precache badge share asset $provider", e, s);
    }
  }
}

Future<RenderRepaintBoundary> _waitForBoundaryReady({
  required GlobalKey repaintKey,
}) async {
  const int maxAttempts = 8;
  const Duration attemptDelay = Duration(milliseconds: 40);

  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    bool needsPaint = false;
    assert(() {
      needsPaint = boundary?.debugNeedsPaint ?? false;
      return true;
    }());
    if (boundary == null) {
      _logger.fine("Badge share boundary missing (attempt ${attempt + 1})");
    } else if (boundary.size.isEmpty) {
      _logger.fine(
        "Badge share boundary has zero size (attempt ${attempt + 1})",
      );
    } else if (needsPaint) {
      _logger.fine(
        "Badge share boundary needs paint (attempt ${attempt + 1}), waiting",
      );
    } else {
      return boundary;
    }
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(attemptDelay);
  }

  final boundary =
      repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError("Render boundary unavailable for badge share");
  }
  if (boundary.size.isEmpty) {
    throw StateError("Render boundary has zero size for badge share");
  }
  bool needsPaint = false;
  assert(() {
    needsPaint = boundary.debugNeedsPaint;
    return true;
  }());
  if (needsPaint) {
    throw StateError("Render boundary not ready to paint for badge share");
  }
  return boundary;
}

class _RitualBadgeShareCard extends StatelessWidget {
  const _RitualBadgeShareCard({required this.badge});

  final RitualBadgeUnlock badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = darkTheme.colorScheme;
    final textTheme = darkTheme.textTheme;
    final l10n = context.l10n;
    final raysColor = _badgeGreen.withValues(alpha: 0.82);
    final badgeAsset = _badgeAssets[badge.days] ?? _badgeAssets[7]!;
    final badgeMessage = _badgeMessage(context, badge.days);
    final title =
        badge.ritual.title.isEmpty ? l10n.ritualUntitled : badge.ritual.title;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.backgroundElevated,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colorScheme.strokeFaint,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: 6,
                right: 6,
                child: Image.asset(
                  "assets/qr_logo.png",
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedOverflowBox(
                      size: ui.Size.zero,
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: const Offset(0, -80),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0, 0.16, 0.84, 1],
                            colors: [
                              Colors.transparent,
                              Colors.white,
                              Colors.white,
                              Colors.transparent,
                            ],
                          ).createShader(bounds),
                          blendMode: BlendMode.dstIn,
                          child: SvgPicture.asset(
                            "assets/rituals/badge_popup_fidgets.svg",
                            fit: BoxFit.cover,
                            width: 220,
                            height: 220,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      l10n.ritualBadgeNewTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Nunito",
                        fontStyle: FontStyle.normal,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.72,
                        height: 1.15,
                        color: colorScheme.textBase,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SvgPicture.asset(
                      "assets/rituals/green_stroke.svg",
                      width: 74,
                      height: 8,
                    ),
                    const SizedBox(height: 14),
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 240,
                          child: OverflowBox(
                            maxWidth: 900,
                            maxHeight: 900,
                            child: Transform.translate(
                              offset: const Offset(0, -100),
                              child: SvgPicture.asset(
                                "assets/rituals/background_rays.svg",
                                width: 900,
                                height: 900,
                                fit: BoxFit.contain,
                                colorFilter: ColorFilter.mode(
                                  raysColor,
                                  BlendMode.srcATop,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Image.asset(
                          badgeAsset,
                          width: 184,
                          height: 184,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    _RitualChip(
                      icon:
                          badge.ritual.icon.isEmpty ? "📸" : badge.ritual.icon,
                      title: title,
                      useDarkTheme: true,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      badgeMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.body.copyWith(
                        fontSize: 18,
                        height: 1.4,
                        color: colorScheme.textBase,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Align(
                      alignment: Alignment.center,
                      child: Image.asset(
                        "assets/ente_io_green.png",
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
