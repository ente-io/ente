import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
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
    return Row(
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
                  radiusValue.toString(),
                  style: radiusValue != 1200
                      ? textTheme.largeBold
                      : textTheme.bodyBold,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  "km",
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
                Text("Radius", style: textTheme.body),
                const SizedBox(height: 10),
                SizedBox(
                  height: 12,
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
}
