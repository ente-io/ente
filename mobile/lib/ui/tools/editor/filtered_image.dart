import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:image_editor/image_editor.dart';

class FilteredImage extends StatelessWidget {
  const FilteredImage({
    required this.child,
    this.brightness,
    this.saturation,
    this.hue,
    super.key,
  });

  final double? brightness, saturation, hue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(
        ColorFilterGenerator.brightnessAdjustMatrix(
          value: brightness ?? 1,
        ),
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(
          ColorFilterGenerator.saturationAdjustMatrix(
            value: saturation ?? 1,
          ),
        ),
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(
            ColorFilterGenerator.hueAdjustMatrix(
              value: hue ?? 0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ColorFilterGenerator {
  static List<double> hueAdjustMatrix({double value = 1}) {
    value = value * pi;

    if (value == 0) {
      return [
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ];
    }
    final double cosVal = cos(value);
    final double sinVal = sin(value);
    const double lumR = 0.213;
    const double lumG = 0.715;
    const double lumB = 0.072;

    return List<double>.from(<double>[
      (lumR + (cosVal * (1 - lumR))) + (sinVal * (-lumR)),
      (lumG + (cosVal * (-lumG))) + (sinVal * (-lumG)),
      (lumB + (cosVal * (-lumB))) + (sinVal * (1 - lumB)),
      0,
      0,
      (lumR + (cosVal * (-lumR))) + (sinVal * 0.143),
      (lumG + (cosVal * (1 - lumG))) + (sinVal * 0.14),
      (lumB + (cosVal * (-lumB))) + (sinVal * (-0.283)),
      0,
      0,
      (lumR + (cosVal * (-lumR))) + (sinVal * (-(1 - lumR))),
      (lumG + (cosVal * (-lumG))) + (sinVal * lumG),
      (lumB + (cosVal * (1 - lumB))) + (sinVal * lumB),
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]).map((i) => i.toDouble()).toList();
  }

  static List<double> brightnessAdjustMatrix({double value = 1}) {
    return ColorOption.brightness(value).matrix;
  }

  static List<double> saturationAdjustMatrix({double value = 1}) {
    return ColorOption.saturation(value).matrix;
  }
}
