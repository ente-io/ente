bool shouldShowNextTotpCode({
  required bool isIOS,
  required double availableWidth,
  required double textScaleFactor,
  required bool isCompactMode,
}) {
  if (isIOS) return true;

  final double minWidth = isCompactMode ? 230 : 320;
  final double scaleAdjustedMinWidth = textScaleFactor >= 1.2
      ? minWidth + (textScaleFactor - 1.2) * 140
      : minWidth;
  return availableWidth >= scaleAdjustedMinWidth;
}
