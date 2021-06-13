import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DurationPicker extends StatefulWidget {
  const DurationPicker({
    Key? key,
    required this.initDuration,
  }) : super(key: key);

  final Duration initDuration;

  @override
  _DurationPickerState createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late int hours =
      widget.initDuration.inMicroseconds ~/ Duration.microsecondsPerHour;
  late int minutes =
      widget.initDuration.inMicroseconds ~/ Duration.microsecondsPerMinute % 60;
  late int seconds =
      widget.initDuration.inMicroseconds ~/ Duration.microsecondsPerSecond % 60;

  @override
  void initState() {
    super.initState();

    print(hours);
    print(minutes);
    print(seconds);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      Duration(
                          hours: hours, minutes: minutes, seconds: seconds),
                    );
                  },
                  child: Text(
                    "Sure",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
            Material(
              child: Container(
                height: 88,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildPicker(
                      title: "h",
                      currentValue: hours,
                      max: 23,
                      valueChanged: (int value) {
                        hours = value;
                        changeDuration();
                      },
                    ),
                    _buildPicker(
                        title: "min",
                        currentValue: minutes,
                        max: 59,
                        valueChanged: (int value) {
                          minutes = value;
                          changeDuration();
                        }),
                    _buildPicker(
                        title: "sec",
                        currentValue: seconds,
                        max: 59,
                        valueChanged: (value) {
                          seconds = value;
                          changeDuration();
                        }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void changeDuration() {
    setState(() {});
  }

  Widget _buildPicker({
    required String title,
    required int currentValue,
    required int max,
    ValueChanged<int>? valueChanged,
  }) {
    return Expanded(
        child: Stack(
      children: <Widget>[
        CupertinoPicker.builder(
          scrollController:
              FixedExtentScrollController(initialItem: currentValue),
          itemExtent: 88,
          childCount: max + 1,
          onSelectedItemChanged: (value) {
            valueChanged?.call(value);
          },
          itemBuilder: (context, index) {
            return Center(
              child: Text(index.toString()),
            );
          },
        ),
        IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 50.0),
              child: Text(title),
            ),
          ),
        ),
      ],
    ));
  }
}

Future<Duration?> showCupertinoDurationPicker({
  required BuildContext context,
  required Duration initDuration,
}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return DurationPicker(
        initDuration: initDuration,
      );
    },
  );
}
