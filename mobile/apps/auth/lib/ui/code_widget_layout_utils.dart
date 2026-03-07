bool shouldShowNextTotpCode({
  required double availableWidth,
  required double textScaleFactor,
  required bool isCompactMode,
}) {
  final double minWidth = isCompactMode ? 230 : 320;
  final double scaleAdjustedMinWidth = textScaleFactor >= 1.2
      ? minWidth + (textScaleFactor - 1.2) * 140
      : minWidth;
  return availableWidth >= scaleAdjustedMinWidth;
}
