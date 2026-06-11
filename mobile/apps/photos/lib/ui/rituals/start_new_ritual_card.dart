import "dart:math" as math;

import "package:dotted_border/dotted_border.dart";
import "package:ente_components/ente_components.dart";
import "package:ente_icons/ente_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/pending_translation.dart";

enum StartNewRitualCardVariant { compact, wide }

class StartNewRitualCard extends StatelessWidget {
  const StartNewRitualCard({
    super.key,
    required this.variant,
    required this.onTap,
  });

  final StartNewRitualCardVariant variant;
  final VoidCallback onTap;

  static const _cardRadius = 25.0;
  static const _cardHeight = 100.0;
  static const _compactHeight = 94.0;
  static const _compactWidth = 167.5;
  static const _wideDuckyHeightReduction = 12.0;
  static const _wideDuckyAspectRatio = 149 / 81;
  static const _wideDuckyRightOverflow = 4.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);

    if (variant == StartNewRitualCardVariant.compact) {
      return _CompactStartNewRitualCard(onTap: onTap);
    }

    final componentColors = context.componentColors;
    const fillColor = Colors.transparent;
    final dottedBorderColor = componentColors.textLightest;
    const duckyHeight = _cardHeight - _wideDuckyHeightReduction;
    const duckyNaturalWidth = duckyHeight * _wideDuckyAspectRatio;
    const duckyChildWidth = duckyNaturalWidth + _wideDuckyRightOverflow;

    return SizedBox(
      height: _cardHeight,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(_cardRadius),
        dashPattern: const [3.75, 3.75],
        strokeWidth: 1.5,
        borderPadding: const EdgeInsets.all(0.75),
        color: dottedBorderColor,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Material(
            color: fillColor,
            child: InkWell(
              onTap: onTap,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  var duckyWidth = 0.0;
                  final textScaler = MediaQuery.textScalerOf(context);
                  final textDirection = Directionality.of(context);
                  const leftPadding = 14.0;
                  const iconWidth = 24.0;
                  const iconSpacing = 10.0;

                  bool fits(double candidateDuckyWidth) {
                    final leftWidth = math.max(
                      0.0,
                      constraints.maxWidth - candidateDuckyWidth,
                    );
                    final titleMaxWidth =
                        leftWidth - leftPadding - iconWidth - iconSpacing;
                    const titleWidthEpsilon = 8.0;
                    final adjustedTitleMaxWidth =
                        titleMaxWidth - titleWidthEpsilon;
                    final subtitleMaxWidth = leftWidth - leftPadding;
                    if (adjustedTitleMaxWidth <= 0 || subtitleMaxWidth <= 0) {
                      return false;
                    }

                    final titlePainter = TextPainter(
                      text: TextSpan(
                        text: pendingTranslation("Start new ritual"),
                        style: textTheme.body,
                      ),
                      maxLines: 1,
                      ellipsis: "…",
                      textDirection: textDirection,
                      textScaler: textScaler,
                      textHeightBehavior: _tightTextHeightBehavior,
                    )..layout(maxWidth: adjustedTitleMaxWidth);
                    if (titlePainter.didExceedMaxLines) return false;

                    final subtitlePainter = TextPainter(
                      text: TextSpan(
                        text: pendingTranslation(
                          "Create a ritual, build streaks, and share your progress.",
                        ),
                        style: textTheme.miniMuted,
                      ),
                      maxLines: 3,
                      ellipsis: "…",
                      textDirection: textDirection,
                      textScaler: textScaler,
                    )..layout(maxWidth: subtitleMaxWidth);
                    return !subtitlePainter.didExceedMaxLines;
                  }

                  final upperBound = math.min(
                    duckyChildWidth,
                    constraints.maxWidth,
                  );
                  if (fits(upperBound)) {
                    duckyWidth = upperBound;
                  } else if (fits(0.0)) {
                    var low = 0.0;
                    var high = upperBound;
                    for (var i = 0; i < 10; i++) {
                      final mid = (low + high) / 2;
                      if (fits(mid)) {
                        low = mid;
                      } else {
                        high = mid;
                      }
                    }
                    duckyWidth = low;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 11, 0, 11),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF2E1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        EnteIcons.lightningFilled,
                                        size: 17,
                                        color: Color(0xFFFFBC03),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      pendingTranslation("Start new ritual"),
                                      style: textTheme.body,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textHeightBehavior:
                                          _tightTextHeightBehavior,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                pendingTranslation(
                                  "Create a ritual, build streaks, and share your progress.",
                                ),
                                style: textTheme.miniMuted,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (duckyWidth > 0)
                        SizedBox(
                          width: duckyWidth,
                          height: double.infinity,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(_cardRadius),
                              bottomRight: Radius.circular(_cardRadius),
                            ),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: SizedBox(
                                width: duckyWidth,
                                height: duckyHeight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.bottomRight,
                                  child: SizedBox(
                                    width: duckyChildWidth,
                                    height: duckyHeight,
                                    child: Transform.translate(
                                      offset: const Offset(
                                        _wideDuckyRightOverflow,
                                        0,
                                      ),
                                      child: SvgPicture.asset(
                                        "assets/rituals/ducky_ritual.svg",
                                        fit: BoxFit.fitHeight,
                                        alignment: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
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
        ),
      ),
    );
  }
}

class _CompactStartNewRitualCard extends StatelessWidget {
  const _CompactStartNewRitualCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final borderRadius = BorderRadius.circular(StartNewRitualCard._cardRadius);
    return SizedBox(
      width: StartNewRitualCard._compactWidth,
      height: StartNewRitualCard._compactHeight,
      child: Material(
        color: colorScheme.fill,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Stack(
            children: [
              const Positioned(
                left: 22,
                top: 19,
                child: Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: Color(0xFFFFBC03),
                ),
              ),
              const Positioned(
                right: 28,
                top: 19,
                child: Icon(
                  Icons.auto_awesome,
                  size: 10,
                  color: Color(0xFFFFD25A),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorScheme.greenBase,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        pendingTranslation("Start new ritual"),
                        style: textTheme.bodyBold.copyWith(
                          color: colorScheme.textBase,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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

const _tightTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);
