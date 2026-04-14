import "dart:math" as math;

import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/email_entry_page.dart";

class GetStartedBanner extends StatefulWidget {
  const GetStartedBanner({super.key});

  @override
  State<GetStartedBanner> createState() => _GetStartedBannerState();
}

class _GetStartedBannerState extends State<GetStartedBanner> {
  static const _contentHorizontalPadding = 16.0;
  static const _subtitleArtworkGap = 8.0;
  static const _duckRightInset = 8.0;
  static const _duckMaxWidth = 188.0;
  static const _duckWidthRatio = 188.0 / 359.0;
  static const _subtitleMaxWidth = 240.0;
  static const _subtitleMinWidth = 160.0;
  // Sampled from the duck PNG's opaque left edge across the subtitle's
  // first and second line bands. This lets the text wrap into the transparent
  // shoulder area without colliding with the visible artwork.
  static const _duckFirstLineOpaqueStartFraction = 0.374;
  static const _duckSecondLineOpaqueStartFraction = 0.328;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (localSettings.isOfflineGetStartedBannerDismissed) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final colorScheme = getEnteColorScheme(context);

    const titleStyle = TextStyle(
      fontFamily: "Nunito",
      fontWeight: FontWeight.w900,
      fontSize: 22,
      height: 22 / 22,
      color: Colors.white,
    );
    // Subtitle uses Inter (the Ente design system default) to match the
    // pre-redesign banner. Inter has all weight files declared in
    // pubspec.yaml, so SemiBold (w600) resolves correctly — Montserrat
    // only ships the Bold file and would render at the wrong weight.
    final descriptionStyle = TextStyle(
      fontFamily: "Inter",
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 20 / 12,
      letterSpacing: -0.2,
      color: Colors.white.withValues(alpha: 0.8),
    );
    const buttonStyle = TextStyle(
      fontFamily: "Nunito",
      fontWeight: FontWeight.w900,
      fontSize: 14,
      height: 14 / 14,
      letterSpacing: -0.48,
      color: Colors.black,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GestureDetector(
        onTap: _onGetStarted,
        child: Container(
          width: double.infinity,
          height: 188,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: colorScheme.greenBase,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final innerWidth = constraints.maxWidth - 32;
              final titleMaxWidth =
                  (innerWidth - 32).clamp(120.0, double.infinity);
              final idealDuckWidth = math.min(
                _duckMaxWidth,
                constraints.maxWidth * _duckWidthRatio,
              );
              final maxDuckWidthForSubtitle = math.max(
                0.0,
                (constraints.maxWidth -
                        _contentHorizontalPadding -
                        _duckRightInset -
                        _subtitleArtworkGap -
                        _subtitleMinWidth) /
                    (1 - _duckSecondLineOpaqueStartFraction),
              );
              final duckWidth = math.min(
                idealDuckWidth,
                maxDuckWidthForSubtitle,
              );
              final firstLineMaxWidth = math.min(
                _subtitleMaxWidth,
                _subtitleLineWidth(
                  bannerWidth: constraints.maxWidth,
                  duckWidth: duckWidth,
                  duckOpaqueStartFraction: _duckFirstLineOpaqueStartFraction,
                ),
              );
              final secondLineMaxWidth = math.min(
                _subtitleMaxWidth,
                _subtitleLineWidth(
                  bannerWidth: constraints.maxWidth,
                  duckWidth: duckWidth,
                  duckOpaqueStartFraction: _duckSecondLineOpaqueStartFraction,
                ),
              );
              final effectiveDescriptionStyle = secondLineMaxWidth < 180
                  ? descriptionStyle.copyWith(
                      fontSize: 11,
                      height: 18 / 11,
                    )
                  : descriptionStyle;

              return Stack(
                children: [
                  Positioned(
                    right: 8,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Image.asset(
                        "assets/ducky_10gb_free.png",
                        width: duckWidth,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: titleMaxWidth,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n.offlineHomeSignupBannerTitle,
                                maxLines: 1,
                                softWrap: false,
                                style: titleStyle,
                              ),
                            ),
                          ),
                          const SizedBox(height: 13),
                          _BannerDescriptionText(
                            text: l10n.offlineHomeSignupBannerDescription,
                            style: effectiveDescriptionStyle,
                            firstLineMaxWidth: firstLineMaxWidth,
                            secondLineMaxWidth: secondLineMaxWidth,
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _onGetStarted,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.offlineHomeSignupBannerAction,
                                style: buttonStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: _onDismiss,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onDismiss() async {
    setState(() {
      _dismissed = true;
    });
    await localSettings.setOfflineGetStartedBannerDismissed(true);
  }

  Future<void> _onGetStarted() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EmailEntryPage(
          showReferralSourceField: false,
          referralSource: "Offline",
        ),
      ),
    );
  }

  double _subtitleLineWidth({
    required double bannerWidth,
    required double duckWidth,
    required double duckOpaqueStartFraction,
  }) {
    final artworkGap = duckWidth > 0 ? _subtitleArtworkGap : 0.0;
    return math.max(
      0.0,
      bannerWidth -
          _contentHorizontalPadding -
          _duckRightInset -
          artworkGap -
          (duckWidth * (1 - duckOpaqueStartFraction)),
    );
  }
}

class _BannerDescriptionText extends StatefulWidget {
  static const _lineHeight = 20.0;

  final String text;
  final TextStyle style;
  final double firstLineMaxWidth;
  final double secondLineMaxWidth;

  const _BannerDescriptionText({
    required this.text,
    required this.style,
    required this.firstLineMaxWidth,
    required this.secondLineMaxWidth,
  });

  @override
  State<_BannerDescriptionText> createState() => _BannerDescriptionTextState();
}

class _BannerDescriptionTextState extends State<_BannerDescriptionText> {
  _SplitBannerDescription? _cachedSplit;
  String? _cachedText;
  double? _cachedFirstLineMaxWidth;
  TextStyle? _cachedStyle;
  TextScaler? _cachedTextScaler;

  @override
  Widget build(BuildContext context) {
    final lines = _splitLines(context);
    final strutStyle = StrutStyle(
      fontFamily: widget.style.fontFamily,
      fontSize: widget.style.fontSize,
      fontWeight: widget.style.fontWeight,
      height: widget.style.height,
      forceStrutHeight: true,
    );

    return SizedBox(
      height: _BannerDescriptionText._lineHeight * 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: widget.firstLineMaxWidth,
            child: Text(
              lines.firstLine,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: widget.style,
              strutStyle: strutStyle,
            ),
          ),
          if (lines.secondLine.isNotEmpty)
            SizedBox(
              width: widget.secondLineMaxWidth,
              child: Text(
                lines.secondLine,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: widget.style,
                strutStyle: strutStyle,
              ),
            )
          else
            const SizedBox(height: _BannerDescriptionText._lineHeight),
        ],
      ),
    );
  }

  _SplitBannerDescription _splitLines(BuildContext context) {
    if (widget.text.isEmpty || widget.firstLineMaxWidth <= 0) {
      return const _SplitBannerDescription("", "");
    }

    final textScaler = MediaQuery.textScalerOf(context);
    if (_cachedSplit != null &&
        _cachedText == widget.text &&
        _cachedFirstLineMaxWidth == widget.firstLineMaxWidth &&
        _cachedStyle == widget.style &&
        _cachedTextScaler == textScaler) {
      return _cachedSplit!;
    }

    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
    )..layout(maxWidth: widget.firstLineMaxWidth);
    final firstLineRange =
        painter.getLineBoundary(const TextPosition(offset: 0));
    final splitIndex = firstLineRange.end.clamp(0, widget.text.length);
    final firstLine = widget.text.substring(0, splitIndex).trimRight();
    final secondLine = widget.text.substring(splitIndex).trimLeft();
    painter.dispose();

    final split = _SplitBannerDescription(firstLine, secondLine);
    _cachedSplit = split;
    _cachedText = widget.text;
    _cachedFirstLineMaxWidth = widget.firstLineMaxWidth;
    _cachedStyle = widget.style;
    _cachedTextScaler = textScaler;
    return split;
  }
}

class _SplitBannerDescription {
  final String firstLine;
  final String secondLine;

  const _SplitBannerDescription(this.firstLine, this.secondLine);
}
