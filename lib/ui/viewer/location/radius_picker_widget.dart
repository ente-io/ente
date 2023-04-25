import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/states/location_state.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const trackHeight = 2.0;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(0, 0, trackWidth, trackHeight);
  }
}

class RadiusPickerWidget extends StatefulWidget {
  ///This notifier can be listened to get the selected radius index from
  ///a parent widget.
  final ValueNotifier<int> selectedRadiusIndexNotifier;
  const RadiusPickerWidget(
    this.selectedRadiusIndexNotifier, {
    super.key,
  });

  @override
  State<RadiusPickerWidget> createState() => _RadiusPickerWidgetState();
}

class _RadiusPickerWidgetState extends State<RadiusPickerWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    widget.selectedRadiusIndexNotifier.value =
        InheritedLocationTagData.of(context).selectedRadiusIndex;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRadiusIndex = widget.selectedRadiusIndexNotifier.value;
    final radiusValue = radiusValues[selectedRadiusIndex];
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    final roundedRadius = roundRadius(radiusValue);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: colorScheme.fillFaint,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: Text(
                  roundedRadius,
                  style: double.parse(roundedRadius) < 1000
                      ? textTheme.largeBold
                      : textTheme.bodyBold,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  S.of(context).kiloMeterUnit,
                  style: textTheme.miniMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.of(context).radius, style: textTheme.body),
                const SizedBox(height: 16),
                SizedBox(
                  height: 16,
                  child: SliderTheme(
                    data: SliderThemeData(
                      overlayColor: Colors.transparent,
                      thumbColor: strokeSolidMutedLight,
                      activeTrackColor: strokeSolidMutedLight,
                      inactiveTrackColor: colorScheme.strokeFaint,
                      activeTickMarkColor: colorScheme.strokeMuted,
                      inactiveTickMarkColor: strokeSolidMutedLight,
                      trackShape: CustomTrackShape(),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                        pressedElevation: 0,
                        elevation: 0,
                      ),
                      tickMarkShape: const RoundSliderTickMarkShape(
                        tickMarkRadius: 1,
                      ),
                    ),
                    child: RepaintBoundary(
                      child: Slider(
                        value: selectedRadiusIndex.toDouble(),
                        onChanged: (value) {
                          setState(() {
                            widget.selectedRadiusIndexNotifier.value =
                                value.toInt();
                          });
                        },
                        min: 0,
                        max: radiusValues.length - 1,
                        divisions: radiusValues.length - 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //9.99 -> 10, 9.0 -> 9, 5.02 -> 5, 5.09 -> 5.1
  //12.3 -> 12, 121.65 -> 122, 999.9 -> 1000
  String roundRadius(double radius) {
    String result;
    final roundedRadius = (radius * 10).round() / 10;
    if (radius >= 10) {
      result = roundedRadius.toStringAsFixed(0);
    } else {
      if (roundedRadius == roundedRadius.truncate()) {
        result = roundedRadius.truncate().toString();
      } else {
        result = roundedRadius.toStringAsFixed(1);
      }
    }

    return result;
  }
}
