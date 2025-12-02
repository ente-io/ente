import "dart:io";
import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:path_provider/path_provider.dart";
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

const Map<int, String> _badgeMessages = {
  7: "7 days down! Consistency looks good on you. Keep going!",
  14: "14 days in! Your ritual is becoming a habit. Incredible!",
  30: "30 days in a row! Legendary consistency. Take a bow!",
};

Future<void> showRitualBadgePopup(
  BuildContext context, {
  required RitualBadgeUnlock badge,
  bool allowShare = true,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final brightness = Theme.of(context).brightness;
    final badgeAsset = _badgeAssets[widget.badge.days] ?? _badgeAssets[7]!;
    final badgeMessage =
        _badgeMessages[widget.badge.days] ?? "You're on a roll!";
    final title = widget.badge.ritual.title.isEmpty
        ? "Untitled ritual"
        : widget.badge.ritual.title;

    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: colorScheme.backgroundBase,
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
                              brightness == Brightness.dark
                                  ? "assets/rituals/badge_popup_fidgets_dark.svg"
                                  : "assets/rituals/badge_popup_fidgets_light.svg",
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      ShaderMask(
                        shaderCallback: (Rect bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.2933, 1],
                          colors: [
                            Color(0xFF545454),
                            Colors.black,
                          ],
                        ).createShader(
                          Rect.fromLTWH(
                            0,
                            0,
                            bounds.width,
                            bounds.height,
                          ),
                        ),
                        blendMode: BlendMode.srcIn,
                        child: const Text(
                          "New achievement",
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                                    _badgeGreen.withValues(alpha: 1.0),
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
                        style: textTheme.bodyMuted.copyWith(
                          fontSize: 18,
                          height: null,
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
                              _sharing ? "Preparing..." : "Share",
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
    );
  }
}

class _RitualChip extends StatelessWidget {
  const _RitualChip({
    required this.icon,
    required this.title,
    this.backgroundColor,
  });

  final String icon;
  final String title;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ??
            (brightness == Brightness.dark
                ? colorScheme.backgroundElevated2
                : Colors.white),
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
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      throw StateError("Overlay not available for badge share");
    }
    final repaintKey = GlobalKey();
    entry = OverlayEntry(
      builder: (_) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: repaintKey,
            child: _RitualBadgeShareCard(badge: badge),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 36));
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError("Render boundary unavailable for badge share");
    }
    if (boundary.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 24));
    }
    final ui.Image image = await boundary.toImage(
      pixelRatio:
          (MediaQuery.of(context).devicePixelRatio * 1.8).clamp(2.4, 3.5),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final data = byteData?.buffer.asUint8List();
    if (data == null) {
      throw StateError("Unable to encode badge image");
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      "${dir.path}/ritual_badge_${badge.days}_${badge.ritual.id}_${DateTime.now().millisecondsSinceEpoch}.png",
    );
    await file.writeAsBytes(data, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        sharePositionOrigin: shareButtonRect(context, shareButtonKey),
      ),
    );
  } catch (e, s) {
    debugPrint("Failed to share ritual badge: $e\n$s");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to share right now. Please try again."),
        ),
      );
    }
  } finally {
    entry?.remove();
  }
}

class _RitualBadgeShareCard extends StatelessWidget {
  const _RitualBadgeShareCard({required this.badge});

  final RitualBadgeUnlock badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final badgeAsset = _badgeAssets[badge.days] ?? _badgeAssets[7]!;
    final badgeMessage =
        _badgeMessages[badge.days] ?? "You're on a roll! Keep going.";
    final title =
        badge.ritual.title.isEmpty ? "Untitled ritual" : badge.ritual.title;
    return Container(
      color: _badgeGreen,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: _badgeGreen,
              borderRadius: BorderRadius.circular(26),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      "assets/rituals/background_rays.svg",
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withValues(alpha: 0.12),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Image.asset(
                            "assets/qr_logo.png",
                            width: 56,
                            height: 56,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            "New achievement",
                            style: textTheme.h3Bold.copyWith(
                              color: Colors.white,
                              fontSize: 22,
                              letterSpacing: -0.2,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: SizedBox(
                            height: 190,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                SizedBox(
                                  width: 190,
                                  height: 190,
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
                                          Colors.white.withValues(alpha: 0.14),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  badgeAsset,
                                  width: 176,
                                  height: 176,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: _RitualChip(
                            icon: badge.ritual.icon.isEmpty
                                ? "📸"
                                : badge.ritual.icon,
                            title: title,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          badgeMessage,
                          textAlign: TextAlign.center,
                          style: textTheme.body.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.35,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            "assets/ente_io_black_white.png",
                            width: 120,
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
        ),
      ),
    );
  }
}
