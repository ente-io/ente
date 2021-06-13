import 'package:flutter/material.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:image_scanner_example/widget/dialog/duration_picker.dart';
import 'package:provider/provider.dart';

class FilterOptionPage extends StatefulWidget {
  @override
  _FilterOptionPageState createState() => _FilterOptionPageState();
}

class _FilterOptionPageState extends State<FilterOptionPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Filter Options.')),
      body: ListView(
        children: <Widget>[
          buildInput(provider.minWidth, "minWidth", (value) {
            provider.minWidth = value;
          }),
          buildInput(provider.maxWidth, "maxWidth", (value) {
            provider.maxWidth = value;
          }),
          buildInput(provider.minHeight, "minHeight", (value) {
            provider.minHeight = value;
          }),
          buildInput(provider.maxHeight, "maxHeight", (value) {
            provider.maxHeight = value;
          }),
          buildIgnoreSize(provider),
          buildNeedTitleCheck(provider),
          buildDurationWidget(
            provider,
            "minDuration",
            provider.minDuration,
            (Duration duration) {
              provider.minDuration = duration;
            },
          ),
          buildDurationWidget(
            provider,
            "maxDuration",
            provider.maxDuration,
            (Duration duration) {
              provider.maxDuration = duration;
            },
          ),
          buildDateTimeWidget(
            provider,
            "Start DateTime",
            provider.startDt,
            (DateTime dateTime) {
              provider.startDt = dateTime;
            },
          ),
          buildDateTimeWidget(
            provider,
            "End DateTime",
            provider.endDt,
            (DateTime dateTime) {
              if (provider.startDt.difference(dateTime) < Duration.zero) {
                provider.endDt = dateTime;
              }
            },
          ),
          buildDateAscCheck(provider),
        ],
      ),
    );
  }

  Widget buildInput(
    String initValue,
    String hintText,
    void onChanged(String value),
  ) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: EdgeInsets.all(8),
        labelText: hintText,
      ),
      onChanged: onChanged,
      initialValue: initValue,
      keyboardType: TextInputType.number,
    );
  }

  Widget buildNeedTitleCheck(PhotoProvider provider) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, snapshot) {
        return CheckboxListTile(
          title: Text('need title'),
          onChanged: (bool? value) {
            provider.needTitle = value;
          },
          value: provider.needTitle,
        );
      },
    );
  }

  Widget buildIgnoreSize(PhotoProvider provider) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, snapshot) {
        return CheckboxListTile(
          title: Text('Ignore size with image'),
          onChanged: (bool? value) {
            provider.ignoreSize = value;
          },
          value: provider.ignoreSize,
        );
      },
    );
  }

  Widget buildDurationWidget(Listenable listenable, String title,
      Duration value, void Function(Duration duration) onChanged) {
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, snapshot) {
        return ListTile(
          title: Text(title),
          subtitle: Text(
            "${value.inHours.toString().padLeft(2, '0')}h"
            " : "
            "${(value.inMinutes % 60).toString().padLeft(2, '0')}m"
            " : "
            "${(value.inSeconds % 60).toString().padLeft(2, '0')}s",
          ),
          onTap: () async {
            final duration = await showCupertinoDurationPicker(
                context: context, initDuration: value);

            if (duration != null) {
              onChanged(duration);
            }
            // final timeOfDay =
            //     TimeOfDay(hour: value.inHours, minute: value.inMinutes);
            // final result =
            //     await showTimePicker(context: context, initialTime: timeOfDay);
            // if (result != null) {
            //   final duration =
            //       Duration(hours: result.hour, minutes: result.minute);
            //   if (duration != null) {
            //     onChanged(duration);
            //   }
            // }
          },
        );
      },
    );
  }

  Widget buildDateTimeWidget(
    PhotoProvider provider,
    String title,
    DateTime startDt,
    void Function(DateTime dateTime) onChange,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text("$startDt"),
      onTap: () async {
        final result = await showDatePicker(
          context: context,
          initialDate: startDt,
          firstDate: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          lastDate: DateTime.now().add(Duration(days: 1)),
        );

        if (result != null) {
          onChange(result);
        }
      },
      trailing: ElevatedButton(
        child: Text("Today"),
        onPressed: () {
          onChange(DateTime.now());
        },
      ),
    );
  }

  Widget buildDateAscCheck(PhotoProvider provider) {
    return CheckboxListTile(
      title: Text("Date sort asc"),
      value: provider.asc,
      onChanged: (bool? value) {
        provider.asc = value;
      },
    );
  }
}
