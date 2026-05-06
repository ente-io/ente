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
  static const _minVisibleDuckWidth = 60.0;
  static const _duckWidthSearchStep = 4.0;
  static const _accessibilityDescriptionWidthFraction = 0.6;
  static const _accessibilityDescriptionMaxLines = 4;
  static const _accessibilityDuckWidthBoost = 1.2;
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
    if (localSettings.isLocalGalleryGetStartedBannerDismissed) {
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

    final textScaler = MediaQuery.textScalerOf(context);
    final titleScaleDown = textScaler.scale(1.0) <= 1.0;
    final titleLines = titleScaleDown ? 1 : 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final innerWidth = constraints.maxWidth - 32;
          final titleMaxWidth = (innerWidth - 32).clamp(120.0, double.infinity);
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
          final sculptedDuckWidth = math.min(
            idealDuckWidth,
            maxDuckWidthForSubtitle,
          );
          final firstLineMaxWidth = math.min(
            _subtitleMaxWidth,
            _subtitleLineWidth(
              bannerWidth: constraints.maxWidth,
              duckWidth: sculptedDuckWidth,
              duckOpaqueStartFraction: _duckFirstLineOpaqueStartFraction,
            ),
          );
          final secondLineMaxWidth = math.min(
            _subtitleMaxWidth,
            _subtitleLineWidth(
              bannerWidth: constraints.maxWidth,
              duckWidth: sculptedDuckWidth,
              duckOpaqueStartFraction: _duckSecondLineOpaqueStartFraction,
            ),
          );

          TextStyle descriptionStyleForWidth(double maxWidth) {
            if (maxWidth < 180) {
              return descriptionStyle.copyWith(fontSize: 11, height: 18 / 11);
            }
            return descriptionStyle;
          }

          var resolvedDuckWidth = sculptedDuckWidth;
          var resolvedFirstLineMaxWidth = firstLineMaxWidth;
          var resolvedSecondLineMaxWidth = secondLineMaxWidth;
          var sculptedDescriptionStyle = descriptionStyleForWidth(
            secondLineMaxWidth,
          );
          var useAccessibilityDescriptionLayout =
              _descriptionNeedsAccessibilityFallback(
            context: context,
            text: l10n.offlineHomeSignupBannerDescription,
            style: sculptedDescriptionStyle,
            firstLineMaxWidth: firstLineMaxWidth,
            secondLineMaxWidth: secondLineMaxWidth,
            textScaler: textScaler,
          );
          if (useAccessibilityDescriptionLayout) {
            for (double candidateDuckWidth =
                    sculptedDuckWidth - _duckWidthSearchStep;
                candidateDuckWidth >= 0;
                candidateDuckWidth -= _duckWidthSearchStep) {
              final candidateFirstLineMaxWidth = math.min(
                _subtitleMaxWidth,
                _subtitleLineWidth(
                  bannerWidth: constraints.maxWidth,
                  duckWidth: candidateDuckWidth,
                  duckOpaqueStartFraction: _duckFirstLineOpaqueStartFraction,
                ),
              );
              final candidateSecondLineMaxWidth = math.min(
                _subtitleMaxWidth,
                _subtitleLineWidth(
                  bannerWidth: constraints.maxWidth,
                  duckWidth: candidateDuckWidth,
                  duckOpaqueStartFraction: _duckSecondLineOpaqueStartFraction,
                ),
              );
              final candidateDescriptionStyle = descriptionStyleForWidth(
                candidateSecondLineMaxWidth,
              );
              final fitsWithCandidateDuck =
                  !_descriptionNeedsAccessibilityFallback(
                context: context,
                text: l10n.offlineHomeSignupBannerDescription,
                style: candidateDescriptionStyle,
                firstLineMaxWidth: candidateFirstLineMaxWidth,
                secondLineMaxWidth: candidateSecondLineMaxWidth,
                textScaler: textScaler,
              );
              if (!fitsWithCandidateDuck) {
                continue;
              }

              if (candidateDuckWidth >= _minVisibleDuckWidth) {
                resolvedDuckWidth = candidateDuckWidth;
                resolvedFirstLineMaxWidth = candidateFirstLineMaxWidth;
                resolvedSecondLineMaxWidth = candidateSecondLineMaxWidth;
                sculptedDescriptionStyle = candidateDescriptionStyle;
                useAccessibilityDescriptionLayout = false;
              }
              break;
            }
          }
          final fallbackDescriptionMaxWidth =
              innerWidth * _accessibilityDescriptionWidthFraction;
          final fallbackDuckWidth = math.min(
            idealDuckWidth,
            math.max(0.0, innerWidth - fallbackDescriptionMaxWidth) *
                _accessibilityDuckWidthBoost,
          );
          final duckWidth = useAccessibilityDescriptionLayout
              ? fallbackDuckWidth
              : resolvedDuckWidth;
          final descriptionMaxWidth = useAccessibilityDescriptionLayout
              ? fallbackDescriptionMaxWidth
              : resolvedSecondLineMaxWidth;
          final effectiveDescriptionStyle = descriptionStyleForWidth(
            descriptionMaxWidth,
          );
          final descriptionLineHeight = _scaledLineHeight(
            effectiveDescriptionStyle,
            textScaler,
          );
          final descriptionLines = useAccessibilityDescriptionLayout
              ? _measureTextLineCount(
                  context: context,
                  text: l10n.offlineHomeSignupBannerDescription,
                  style: effectiveDescriptionStyle,
                  maxWidth: descriptionMaxWidth,
                  textScaler: textScaler,
                  maxLines: _accessibilityDescriptionMaxLines,
                )
              : 2;
          final titleLineHeight = _scaledLineHeight(titleStyle, textScaler);
          final buttonLineHeight = _scaledLineHeight(buttonStyle, textScaler);
          final requiredHeight = 18.0 /*top padding*/ +
              titleLineHeight * titleLines +
              13.0 /*title-desc gap*/ +
              descriptionLineHeight * descriptionLines +
              16.0 /*min gap above button*/ +
              buttonLineHeight +
              24.0 /*button vertical padding*/ +
              16.0 /*bottom padding*/;
          final containerHeight = math.max(188.0, requiredHeight);

          return GestureDetector(
            onTap: _onGetStarted,
            child: Container(
              width: double.infinity,
              height: containerHeight,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: colorScheme.greenBase,
              ),
              child: Stack(
                children: [
                  if (duckWidth > 0)
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
                            child: titleScaleDown
                                // Default text scale: preserve the original
                                // single-line scale-down behaviour so narrow
                                // devices still fit the title on one line.
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      l10n.offlineHomeSignupBannerTitle,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: titleStyle,
                                    ),
                                  )
                                // Accessibility text scale: honour the user's
                                // requested size by wrapping to two lines
                                // instead of shrinking the title back down.
                                : Text(
                                    l10n.offlineHomeSignupBannerTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                          ),
                          const SizedBox(height: 13),
                          if (useAccessibilityDescriptionLayout)
                            SizedBox(
                              width: descriptionMaxWidth,
                              child: Text(
                                l10n.offlineHomeSignupBannerDescription,
                                maxLines: _accessibilityDescriptionMaxLines,
                                overflow: TextOverflow.ellipsis,
                                style: effectiveDescriptionStyle,
                                strutStyle: StrutStyle(
                                  fontFamily:
                                      effectiveDescriptionStyle.fontFamily,
                                  fontSize: effectiveDescriptionStyle.fontSize,
                                  fontWeight:
                                      effectiveDescriptionStyle.fontWeight,
                                  height: effectiveDescriptionStyle.height,
                                  forceStrutHeight: true,
                                ),
                              ),
                            )
                          else
                            _BannerDescriptionText(
                              text: l10n.offlineHomeSignupBannerDescription,
                              style: effectiveDescriptionStyle,
                              firstLineMaxWidth: resolvedFirstLineMaxWidth,
                              secondLineMaxWidth: resolvedSecondLineMaxWidth,
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
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onDismiss() async {
    setState(() {
      _dismissed = true;
    });
    await localSettings.setLocalGalleryGetStartedBannerDismissed(true);
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

  bool _descriptionNeedsAccessibilityFallback({
    required BuildContext context,
    required String text,
    required TextStyle style,
    required double firstLineMaxWidth,
    required double secondLineMaxWidth,
    required TextScaler textScaler,
  }) {
    if (text.isEmpty || firstLineMaxWidth <= 0 || secondLineMaxWidth <= 0) {
      return true;
    }

    final firstLinePainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
    )..layout(maxWidth: firstLineMaxWidth);
    final firstLineRange = firstLinePainter.getLineBoundary(
      const TextPosition(offset: 0),
    );
    final splitIndex = firstLineRange.end.clamp(0, text.length);
    final secondLine = text.substring(splitIndex).trimLeft();
    firstLinePainter.dispose();

    if (secondLine.isEmpty) {
      return false;
    }

    final secondLinePainter = TextPainter(
      text: TextSpan(text: secondLine, style: style),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
      maxLines: 1,
      ellipsis: "\u2026",
    )..layout(maxWidth: secondLineMaxWidth);
    final needsFallback = secondLinePainter.didExceedMaxLines;
    secondLinePainter.dispose();
    return needsFallback;
  }

  int _measureTextLineCount({
    required BuildContext context,
    required String text,
    required TextStyle style,
    required double maxWidth,
    required TextScaler textScaler,
    int? maxLines,
  }) {
    if (text.isEmpty || maxWidth <= 0) {
      return 0;
    }

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : "\u2026",
    )..layout(maxWidth: maxWidth);
    final lineCount = painter.computeLineMetrics().length;
    painter.dispose();
    if (maxLines == null) {
      return lineCount;
    }
    return lineCount.clamp(1, maxLines);
  }

  double _scaledLineHeight(TextStyle style, TextScaler textScaler) {
    final fontSize = style.fontSize ?? 14.0;
    return textScaler.scale(fontSize) * (style.height ?? 1.0);
  }
}

class _BannerDescriptionText extends StatefulWidget {
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
    final textScaler = MediaQuery.textScalerOf(context);
    final fontSize = widget.style.fontSize ?? 12.0;
    final lineHeight =
        textScaler.scale(fontSize) * (widget.style.height ?? 1.0);
    final strutStyle = StrutStyle(
      fontFamily: widget.style.fontFamily,
      fontSize: widget.style.fontSize,
      fontWeight: widget.style.fontWeight,
      height: widget.style.height,
      forceStrutHeight: true,
    );

    return SizedBox(
      height: lineHeight * 2,
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
            SizedBox(height: lineHeight),
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
    final firstLineRange = painter.getLineBoundary(
      const TextPosition(offset: 0),
    );
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
