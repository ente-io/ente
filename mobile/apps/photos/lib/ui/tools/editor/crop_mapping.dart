import 'dart:math' as math;
import 'dart:ui';

/// Integer aspect ratio representation to avoid float drift (e.g., 16:9).
class IntAR {
  final int aw; // width units
  final int ah; // height units
  const IntAR(this.aw, this.ah)
      : assert(aw > 0),
        assert(ah > 0);

  /// Convert double ratio to an integer ratio using a bounded continued fraction.
  static IntAR fromDouble(double r, {int maxDen = 1000}) {
    if (r.isNaN || r.isInfinite || r <= 0) {
      return const IntAR(1, 1);
    }
    int a0 = r.floor();
    double frac = r - a0;
    if (frac == 0) return IntAR(a0, 1);
    int num1 = 1, den1 = 0, num = a0, den = 1;
    double x = r;
    while (den <= maxDen) {
      final a = x.floor();
      final num2 = a * num + num1;
      final den2 = a * den + den1;
      if ((num2 / den2 - r).abs() < 1e-9 || den2 > maxDen) {
        break;
      }
      num1 = num;
      den1 = den;
      num = num2;
      den = den2;
      final rem = x - a;
      if (rem == 0) break;
      x = 1 / rem;
    }
    return IntAR(num, den);
  }
}

/// Anchors detected from the display-space selection.
class Anchors {
  final bool left, right, top, bottom;
  final bool centerX, centerY;
  const Anchors({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.centerX,
    required this.centerY,
  });
}

/// File-space crop rectangle (pixel-aligned integers).
class CropRect {
  final int x, y, w, h;
  const CropRect(this.x, this.y, this.w, this.h);

  Rect toRect() => Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
}

/// Result of building a display-space rect with its anchors.
class DisplayRectResult {
  final Rect rect;
  final Anchors anchors;
  const DisplayRectResult({required this.rect, required this.anchors});
}

class CropMapping {
  static const double _epsAnchor = 0.02; // to detect locked edges in normalized coords
  static const double _epsMerge = 0.001; // to merge near-degenerate boxes

  /// Build the enforced display-space rectangle from normalized min/max and optional aspect ratio.
  static DisplayRectResult buildDisplayRect({
    required Size displaySize,
    required Offset minCrop,
    required Offset maxCrop,
    IntAR? ar, // aspect ratio in display space (width:height)
  }) {
    // Normalize/sort and clamp to [0,1]
    double minX = math.min(minCrop.dx, maxCrop.dx).clamp(0.0, 1.0);
    double maxX = math.max(minCrop.dx, maxCrop.dx).clamp(0.0, 1.0);
    double minY = math.min(minCrop.dy, maxCrop.dy).clamp(0.0, 1.0);
    double maxY = math.max(minCrop.dy, maxCrop.dy).clamp(0.0, 1.0);

    // Handle degenerate tiny selections by expanding to 1 pixel in display space.
    if ((maxX - minX) * displaySize.width < 1) {
      final cx = (minX + maxX) / 2;
      minX = (cx - 0.5 / displaySize.width).clamp(0.0, 1.0);
      maxX = (cx + 0.5 / displaySize.width).clamp(0.0, 1.0);
    }
    if ((maxY - minY) * displaySize.height < 1) {
      final cy = (minY + maxY) / 2;
      minY = (cy - 0.5 / displaySize.height).clamp(0.0, 1.0);
      maxY = (cy + 0.5 / displaySize.height).clamp(0.0, 1.0);
    }

    final lockLeft = (minX <= _epsAnchor);
    final lockRight = ((1.0 - maxX) <= _epsAnchor);
    final lockTop = (minY <= _epsAnchor);
    final lockBottom = ((1.0 - maxY) <= _epsAnchor);
    final centerX = !(lockLeft || lockRight);
    final centerY = !(lockTop || lockBottom);

    Rect raw = Rect.fromLTRB(
      minX * displaySize.width,
      minY * displaySize.height,
      maxX * displaySize.width,
      maxY * displaySize.height,
    );

    if (ar == null) {
      return DisplayRectResult(
        rect: raw,
        anchors: Anchors(
          left: lockLeft,
          right: lockRight,
          top: lockTop,
          bottom: lockBottom,
          centerX: centerX,
          centerY: centerY,
        ),
      );
    }

    // CONTAIN by default within raw; COVER only if both edges locked on an axis.
    final aw = ar.aw, ah = ar.ah;
    final dw = raw.width, dh = raw.height;

    // contain: fit ar inside raw using integer comparison (dw*ah vs dh*aw)
    double cw, ch;
    if (dw * ah <= dh * aw) {
      cw = dw;
      ch = dw * ah / aw;
    } else {
      ch = dh;
      cw = dh * aw / ah;
    }

    double left = raw.left, top = raw.top;

    // Horizontal COVER if both edges locked and full width increases area and fits.
    if (lockLeft && lockRight) {
      final double fullH = displaySize.width * ah / aw;
      if (fullH <= displaySize.height + _epsMerge && fullH * displaySize.width > cw * ch) {
        left = 0;
        top = _anchorY(top, raw.bottom, fullH, lockTop, lockBottom, displaySize.height);
        return DisplayRectResult(
          rect: Rect.fromLTWH(left, top, displaySize.width, fullH),
          anchors: Anchors(
            left: lockLeft,
            right: lockRight,
            top: lockTop,
            bottom: lockBottom,
            centerX: centerX,
            centerY: centerY,
          ),
        );
      }
    }
    // Vertical COVER if both edges locked and full height increases area and fits.
    if (lockTop && lockBottom) {
      final double fullW = displaySize.height * aw / ah;
      if (fullW <= displaySize.width + _epsMerge && fullW * displaySize.height > cw * ch) {
        top = 0;
        left = _anchorX(left, raw.right, fullW, lockLeft, lockRight, displaySize.width);
        return DisplayRectResult(
          rect: Rect.fromLTWH(left, top, fullW, displaySize.height),
          anchors: Anchors(
            left: lockLeft,
            right: lockRight,
            top: lockTop,
            bottom: lockBottom,
            centerX: centerX,
            centerY: centerY,
          ),
        );
      }
    }

    // Default: CONTAIN inside raw, honoring locks per axis.
    left = _placeWithin(
      rawLeft: raw.left,
      rawRight: raw.right,
      length: cw,
      lockStart: lockLeft,
      lockEnd: lockRight,
    );
    top = _placeWithin(
      rawLeft: raw.top,
      rawRight: raw.bottom,
      length: ch,
      lockStart: lockTop,
      lockEnd: lockBottom,
    );

    return DisplayRectResult(
      rect: Rect.fromLTWH(left, top, cw, ch),
      anchors: Anchors(
        left: lockLeft,
        right: lockRight,
        top: lockTop,
        bottom: lockBottom,
        centerX: centerX,
        centerY: centerY,
      ),
    );
  }

  static double _placeWithin({
    required double rawLeft,
    required double rawRight,
    required double length,
    required bool lockStart,
    required bool lockEnd,
  }) {
    if (lockStart && !lockEnd) return rawLeft;
    if (!lockStart && lockEnd) return rawRight - length;
    final double center = (rawLeft + rawRight) / 2;
    return center - length / 2;
  }

  static double _anchorY(
    double top,
    double bottom,
    double h,
    bool lockTop,
    bool lockBottom,
    double maxH,
  ) {
    if (lockTop && !lockBottom) return top;
    if (!lockTop && lockBottom) return bottom - h;
    return (maxH - h) / 2;
  }

  static double _anchorX(
    double left,
    double right,
    double w,
    bool lockLeft,
    bool lockRight,
    double maxW,
  ) {
    if (lockLeft && !lockRight) return left;
    if (!lockLeft && lockRight) return right - w;
    return (maxW - w) / 2;
  }

  /// Map enforced display rect → file space, snap to chroma grid (inside-only), return integers.
  static CropRect mapToFile({
    required Rect dispRect,
    required Anchors dispAnchors,
    required Size displaySize,
    required Size fileSize,
    required int metadataRotation, // 0|90|180|270
    String pixelFmt = 'yuv420p',
  }) {
    final rot = ((metadataRotation % 360) + 360) % 360;

    // 1) Normalise rect to [0,1] in display space (content viewport) then map analytically
    final double displayW = displaySize.width;
    final double displayH = displaySize.height;
    assert(displayW > 0 && displayH > 0,
        'Display size must be non-zero when mapping crop rect');

    final double minXNorm = (dispRect.left / displayW).clamp(0.0, 1.0);
    final double maxXNorm = (dispRect.right / displayW).clamp(0.0, 1.0);
    final double minYNorm = (dispRect.top / displayH).clamp(0.0, 1.0);
    final double maxYNorm = (dispRect.bottom / displayH).clamp(0.0, 1.0);

    double minX = 0, minY = 0, maxX = 0, maxY = 0;
    final fileW = fileSize.width;
    final fileH = fileSize.height;

    switch (rot) {
      case 0:
        minX = minXNorm * fileW;
        maxX = maxXNorm * fileW;
        minY = minYNorm * fileH;
        maxY = maxYNorm * fileH;
        break;
      case 90:
        minX = minYNorm * fileW;
        maxX = maxYNorm * fileW;
        minY = (1.0 - maxXNorm) * fileH;
        maxY = (1.0 - minXNorm) * fileH;
        break;
      case 180:
        minX = (1.0 - maxXNorm) * fileW;
        maxX = (1.0 - minXNorm) * fileW;
        minY = (1.0 - maxYNorm) * fileH;
        maxY = (1.0 - minYNorm) * fileH;
        break;
      case 270:
        minX = (1.0 - maxYNorm) * fileW;
        maxX = (1.0 - minYNorm) * fileW;
        minY = minXNorm * fileH;
        maxY = maxXNorm * fileH;
        break;
      default:
        minX = minXNorm * fileW;
        maxX = maxXNorm * fileW;
        minY = minYNorm * fileH;
        maxY = maxYNorm * fileH;
        break;
    }

    minX = minX.clamp(0.0, fileW);
    maxX = maxX.clamp(minX, fileW);
    minY = minY.clamp(0.0, fileH);
    maxY = maxY.clamp(minY, fileH);

    double w = (maxX - minX).clamp(0.0, fileW);
    double h = (maxY - minY).clamp(0.0, fileH);

    // 2) Remap anchors to file space for rounding/snapping behavior.
    final fa = _remapAnchors(dispAnchors, rot);

    // 3) Chroma grid steps by pixel format.
    final int stepX = pixelFmt == 'yuv422'
        ? 2
        : (pixelFmt == 'yuv444'
            ? 1
            : 2); // default 4:2:0 → 2
    final int stepY = pixelFmt == 'yuv422' ? 1 : (pixelFmt == 'yuv444' ? 1 : 2);
    final int stepW = stepX; // conservative
    final int stepH = stepY;

    // Helpers: inside-only snapping and alignment (inward preference)
    double _floorToStep(double v, int step) => (v / step).floorToDouble() * step;
    double _ceilToStep(double v, int step) => (v / step).ceilToDouble() * step;
    double _roundToStep(double v, int step) => (v / step).roundToDouble() * step;

    // 4) Inside-only snap of width/height
    double ws = _floorToStep(w, stepW);
    if (ws < stepW) ws = stepW.toDouble();
    double hs = _floorToStep(h, stepH);
    if (hs < stepH) hs = stepH.toDouble();

    final right = minX + w;
    final bottom = minY + h;
    final cxx = minX + w / 2;
    final cyy = minY + h / 2;

    double x, y;
    if (fa.left && !fa.right) {
      final leftAligned = _ceilToStep(minX, stepX);
      ws = _floorToStep(right - leftAligned, stepW);
      x = leftAligned;
    } else if (!fa.left && fa.right) {
      final rightAligned = _floorToStep(right, stepX);
      x = _floorToStep(rightAligned - ws, stepX);
    } else {
      x = _roundToStep(cxx - ws / 2, stepX);
    }

    if (fa.top && !fa.bottom) {
      final topAligned = _ceilToStep(minY, stepY);
      hs = _floorToStep(bottom - topAligned, stepH);
      y = topAligned;
    } else if (!fa.top && fa.bottom) {
      final bottomAligned = _floorToStep(bottom, stepY);
      y = _floorToStep(bottomAligned - hs, stepY);
    } else {
      y = _roundToStep(cyy - hs / 2, stepY);
    }

    // 5) Clamp and shrink if needed; never grow
    x = x.clamp(0.0, fileSize.width - ws);
    y = y.clamp(0.0, fileSize.height - hs);
    if (x + ws > fileSize.width) {
      ws = _floorToStep(fileSize.width - x, stepW);
    }
    if (y + hs > fileSize.height) {
      hs = _floorToStep(fileSize.height - y, stepH);
    }

    return CropRect(x.round(), y.round(), ws.round(), hs.round());
  }

  static Anchors _remapAnchors(Anchors a, int rot) {
    switch (rot) {
      case 0:
        return Anchors(
          left: a.left,
          right: a.right,
          top: a.top,
          bottom: a.bottom,
          centerX: a.centerX,
          centerY: a.centerY,
        );
      case 90:
        return Anchors(
          left: a.top,
          right: a.bottom,
          top: a.right,
          bottom: a.left,
          centerX: a.centerY,
          centerY: a.centerX,
        );
      case 180:
        return Anchors(
          left: a.right,
          right: a.left,
          top: a.bottom,
          bottom: a.top,
          centerX: a.centerX,
          centerY: a.centerY,
        );
      case 270:
        return Anchors(
          left: a.bottom,
          right: a.top,
          top: a.left,
          bottom: a.right,
          centerX: a.centerY,
          centerY: a.centerX,
        );
      default:
        return Anchors(
          left: a.left,
          right: a.right,
          top: a.top,
          bottom: a.bottom,
          centerX: a.centerX,
          centerY: a.centerY,
        );
    }
  }
}
