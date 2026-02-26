import "dart:math" as math;

import "package:dotted_border/dotted_border.dart";
import "package:ente_icons/ente_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:photos/theme/ente_theme.dart";

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
  static const _compactWidth = 220.0;
  static const _wideDuckyHeightReduction = 12.0;
  static const _wideDuckyAspectRatio = 149 / 81;
  static const _wideDuckyRightOverflow = 4.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const fillColor = Colors.transparent;
    final dottedBorderColor =
        isDark ? colorScheme.strokeFaint : const Color(0xFFF0F0F0);
    final contentRightPadding =
        variant == StartNewRitualCardVariant.compact ? 14.0 : 0.0;
    const duckyHeight = _cardHeight - _wideDuckyHeightReduction;
    const duckyNaturalWidth = duckyHeight * _wideDuckyAspectRatio;
    const duckyChildWidth = duckyNaturalWidth + _wideDuckyRightOverflow;

    return SizedBox(
      width:
          variant == StartNewRitualCardVariant.compact ? _compactWidth : null,
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
                  if (variant == StartNewRitualCardVariant.wide) {
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
                      final titleMaxWidth = leftWidth -
                          leftPadding -
                          contentRightPadding -
                          iconWidth -
                          iconSpacing;
                      const titleWidthEpsilon = 8.0;
                      final adjustedTitleMaxWidth =
                          titleMaxWidth - titleWidthEpsilon;
                      final subtitleMaxWidth =
                          leftWidth - leftPadding - contentRightPadding;
                      if (adjustedTitleMaxWidth <= 0 || subtitleMaxWidth <= 0) {
                        return false;
                      }

                      final titlePainter = TextPainter(
                        text: TextSpan(
                          text: "Start new ritual",
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
                          text:
                              "Create a ritual, build streaks, and share your progress.",
                          style: textTheme.miniMuted,
                        ),
                        maxLines: 3,
                        ellipsis: "…",
                        textDirection: textDirection,
                        textScaler: textScaler,
                      )..layout(maxWidth: subtitleMaxWidth);
                      return !subtitlePainter.didExceedMaxLines;
                    }

                    final upperBound =
                        math.min(duckyChildWidth, constraints.maxWidth);
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
                    } else {
                      duckyWidth = 0.0;
                    }
                  }

                  final showDucky = variant == StartNewRitualCardVariant.wide &&
                      duckyWidth > 0;

                  return Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            14,
                            11,
                            contentRightPadding,
                            11,
                          ),
                          child: Column(
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
                                      "Start new ritual",
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
                                "Create a ritual, build streaks, and share your progress.",
                                style: textTheme.miniMuted,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showDucky)
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

const _tightTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);
