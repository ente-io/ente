import "package:flutter/cupertino.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";

class DateTimePickerWidget extends StatefulWidget {
  final Function(DateTime) onDateTimeSelected;
  final Function() onCancel;
  final DateTime initialDateTime;
  final DateTime maxDateTime;
  final bool startWithTime;

  const DateTimePickerWidget(
    this.onDateTimeSelected,
    this.onCancel,
    this.initialDateTime,
    this.maxDateTime, {
    this.startWithTime = false,
    super.key,
  });

  @override
  State<DateTimePickerWidget> createState() => _DateTimePickerWidgetState();
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {
  late DateTime _selectedDateTime;
  bool _showTimePicker = false;

  @override
  void initState() {
    super.initState();
    _showTimePicker = widget.startWithTime;
    _selectedDateTime = widget.initialDateTime;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      color: colorScheme.backgroundElevated,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _showTimePicker
                    ? S.of(context).selectTime
                    : S.of(context).selectDate,
                style: TextStyle(
                  color: colorScheme.textBase,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Date/Time Picker
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: colorScheme.backgroundElevated2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: colorScheme.textBase,
                    fontSize: 22,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                key: ValueKey(_showTimePicker),
                mode: _showTimePicker
                    ? CupertinoDatePickerMode.time
                    : CupertinoDatePickerMode.date,
                initialDateTime: _selectedDateTime,
                minimumDate: DateTime(1800),
                maximumDate: widget.maxDateTime,
                use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                showDayOfWeek: true,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    if (_showTimePicker) {
                      // Keep the date but update the time
                      _selectedDateTime = DateTime(
                        _selectedDateTime.year,
                        _selectedDateTime.month,
                        _selectedDateTime.day,
                        newDateTime.hour,
                        newDateTime.minute,
                      );
                    } else {
                      // Keep the time but update the date
                      _selectedDateTime = DateTime(
                        newDateTime.year,
                        newDateTime.month,
                        newDateTime.day,
                        _selectedDateTime.hour,
                        _selectedDateTime.minute,
                      );
                    }

                    // Ensure the selected date doesn't exceed maxDateTime
                    if (_selectedDateTime.isAfter(widget.maxDateTime)) {
                      _selectedDateTime = widget.maxDateTime;
                    }
                  });
                },
              ),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cancel Button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    _showTimePicker
                        ? S.of(context).previous
                        : S.of(context).cancel,
                    style: TextStyle(
                      color: colorScheme.textBase,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    if (_showTimePicker) {
                      // Go back to date picker
                      setState(() {
                        _showTimePicker = false;
                      });
                    } else {
                      widget.onCancel();
                    }
                  },
                ),

                // Next/Done Button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    _showTimePicker ? S.of(context).done : S.of(context).next,
                    style: TextStyle(
                      color: colorScheme.primary700,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    if (_showTimePicker) {
                      // We're done, call the callback
                      widget.onDateTimeSelected(_selectedDateTime);
                    } else {
                      // Move to time picker
                      setState(() {
                        _showTimePicker = true;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
