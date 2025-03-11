import "package:flutter/cupertino.dart";
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import "package:photos/models/file/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/magic_util.dart";

class BulkEditDateBottomSheet extends StatefulWidget {
  final Iterable<EnteFile> enteFiles;

  const BulkEditDateBottomSheet({
    super.key,
    required this.enteFiles,
  });

  @override
  State<BulkEditDateBottomSheet> createState() =>
      _BulkEditDateBottomSheetState();
}

class _BulkEditDateBottomSheetState extends State<BulkEditDateBottomSheet> {
  // Single date or shift date
  bool showSingleOrShiftChoice = false;
  bool selectSingleDate = false;

  bool selectingDate = false;
  bool selectingTime = false;

  late DateTime selectedDate;
  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    if (widget.enteFiles.length == 1) {
      selectSingleDate = true;
    } else if (widget.enteFiles.length > 1) {
      showSingleOrShiftChoice = true;
    }
    final firstFileTime = DateTime.fromMicrosecondsSinceEpoch(
      widget.enteFiles.first.creationTime!,
    );
    startDate = firstFileTime;
    endDate = firstFileTime;
    for (final file in widget.enteFiles) {
      if (file.creationTime == null) {
        continue;
      }
      final fileTime = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      if (fileTime.isBefore(startDate)) {
        startDate = fileTime;
      }
      if (fileTime.isAfter(endDate)) {
        endDate = fileTime;
      }
    }
    selectedDate = startDate;
  }

  @override
  Widget build(BuildContext context) {
    final photoCount = widget.enteFiles.length;
    if (photoCount == 0) {
      return const SizedBox.shrink();
    }

    final colorScheme = getEnteColorScheme(context);
    DateTime maxDate = DateTime.now();
    if (!selectSingleDate) {
      final maxForward = DateTime.now().difference(endDate);
      maxDate = startDate.add(maxForward);
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo count and date range section
            PhotoDateHeaderWidget(
              enteFiles: widget.enteFiles,
              startDate: startDate,
              endDate: endDate,
            ),
            if (showSingleOrShiftChoice)
              SelectDateOrShiftWidget(
                onSelectOneDate: () {
                  showSingleOrShiftChoice = false;
                  selectSingleDate = true;
                  setState(() {});
                },
                onShiftDates: () {
                  showSingleOrShiftChoice = false;
                  selectSingleDate = false;
                  setState(() {});
                },
              ),
            if (!showSingleOrShiftChoice && !selectingDate && !selectingTime)
              DateAndTimeWidget(
                key: ValueKey(selectedDate.toString()),
                dateTime: selectedDate,
                selectDate: selectSingleDate,
                singleFile: photoCount == 1,
                newRangeEnd: (selectedDate != startDate && !selectSingleDate)
                    ? endDate.add(selectedDate.difference(startDate))
                    : null,
                onPressedDate: () {
                  selectingDate = true;
                  selectingTime = false;
                  setState(() {});
                },
                onPressedTime: () {
                  selectingDate = false;
                  selectingTime = true;
                  setState(() {});
                },
              ),
            if (selectingDate || selectingTime)
              DateTimePickerWidget(
                (DateTime dateTime) {
                  selectedDate = dateTime;
                  selectingDate = false;
                  selectingTime = false;
                  setState(() {});
                },
                () {
                  selectingDate = false;
                  selectingTime = false;
                  setState(() {});
                },
                selectedDate,
                maxDate,
                startWithTime: selectingTime,
              ),
            if (!showSingleOrShiftChoice &&
                !selectingDate &&
                !selectingTime &&
                selectedDate != startDate)
              Column(
                children: [
                  const SizedBox(height: 16),
                  ButtonWidget(
                    buttonType: ButtonType.primary,
                    labelText: "Confirm",
                    buttonSize: ButtonSize.large,
                    onTap: () async {
                      await _editDates(
                        context,
                        widget.enteFiles,
                        selectedDate,
                        selectSingleDate ? null : startDate,
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 8),
                  ButtonWidget(
                    buttonType: ButtonType.neutral,
                    labelText: "Cancel",
                    buttonSize: ButtonSize.large,
                    onTap: () async {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            // Bottom indicator line
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

Future<void> _editDates(
  BuildContext context,
  Iterable<EnteFile> enteFiles,
  DateTime newDate,
  DateTime? firstDateForShift,
) async {
  if (firstDateForShift != null) {
    final firstDateDiff = newDate.difference(firstDateForShift);
    for (final file in enteFiles) {
      if (file.creationTime == null) {
        continue;
      }
      final fileTime = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      final newTime = fileTime.add(firstDateDiff);
      await editTime(
        context,
        [file],
        newTime.microsecondsSinceEpoch,
      );
    }
  } else {
    await editTime(
      context,
      enteFiles.toList(),
      newDate.microsecondsSinceEpoch,
    );
  }
}

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
                _showTimePicker ? "Select time" : "Select date",
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
                    _showTimePicker ? "Previous" : "Cancel",
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
                    _showTimePicker ? "Done" : "Next",
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

class DateAndTimeWidget extends StatelessWidget {
  const DateAndTimeWidget({
    super.key,
    required this.dateTime,
    required this.selectDate,
    required this.onPressedDate,
    required this.onPressedTime,
    required this.singleFile,
    required this.newRangeEnd,
  });

  final DateTime dateTime;
  final bool selectDate;
  final bool singleFile;
  final DateTime? newRangeEnd;

  final Function() onPressedDate;
  final Function() onPressedTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final locale = Localizations.localeOf(context);
    final String date = DateFormat.yMMMd(locale.languageCode).format(dateTime);
    final String time = DateFormat.Hm(locale.languageCode).format(dateTime);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          if (!singleFile)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectDate
                    ? "Select one date and time for all"
                    : "Select start of range",
                style: TextStyle(
                  color: colorScheme.textBase,
                  fontSize: 16,
                ),
              ),
            ),
          if (!singleFile) const SizedBox(height: 8),
          if (!singleFile)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectDate
                    ? "This will make the date and time of all selected photos the same."
                    : "This is the first in the group. Other selected photos will automatically shift based on this new date",
                style: TextStyle(
                  color: colorScheme.textFaint,
                  fontSize: 12,
                ),
              ),
            ),
          if (!singleFile) const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.backgroundElevated2,
              border: Border.all(
                color: colorScheme.strokeFaint,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.calendar_today_outlined,
                    color: colorScheme.textBase,
                  ),
                  title: Text(
                    date,
                    style: TextStyle(
                      color: colorScheme.textBase,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.strokeMuted,
                  ),
                  onTap: () => onPressedDate(),
                ),
                Divider(
                  color: colorScheme.blurStrokeFaint,
                  indent: 16,
                  endIndent: 16,
                  height: 0.5,
                ),
                ListTile(
                  leading: Icon(
                    Icons.access_time_outlined,
                    color: colorScheme.textBase,
                  ),
                  title: Text(
                    time,
                    style: TextStyle(
                      color: colorScheme.textBase,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.strokeMuted,
                  ),
                  onTap: () => onPressedTime(),
                ),
              ],
            ),
          ),
          if (newRangeEnd != null) const SizedBox(height: 16),
          if (newRangeEnd != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "New range",
                style: TextStyle(
                  color: colorScheme.textBase,
                  fontSize: 12,
                ),
              ),
            ),
          if (newRangeEnd != null) const SizedBox(height: 8),
          if (newRangeEnd != null)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.backgroundElevated2,
                border: Border.all(
                  color: colorScheme.strokeFaint,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: colorScheme.textBase,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(dateTime, locale),
                            style: TextStyle(
                              color: colorScheme.textFaint,
                              fontSize: 12,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "-",
                              style: TextStyle(
                                color: colorScheme.textFaint,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(newRangeEnd!, locale),
                            style: TextStyle(
                              color: colorScheme.textFaint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (newRangeEnd != null) const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class SelectDateOrShiftWidget extends StatelessWidget {
  const SelectDateOrShiftWidget({
    super.key,
    required this.onSelectOneDate,
    required this.onShiftDates,
  });

  final Function() onSelectOneDate;
  final Function() onShiftDates;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated2,
          border: Border.all(
            color: colorScheme.strokeFaint,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Select one date option
            ListTile(
              leading: Icon(
                Icons.calendar_today_outlined,
                color: colorScheme.textBase,
              ),
              title: Text(
                "Select one date and time",
                style: TextStyle(
                  color: colorScheme.textBase,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                "Move selected photos to one date",
                style: TextStyle(
                  color: colorScheme.textFaint,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.strokeMuted,
              ),
              onTap: () => onSelectOneDate(),
            ),
            Divider(
              color: colorScheme.blurStrokeFaint,
              indent: 16,
              endIndent: 16,
              height: 0.5,
            ),
            // Shift dates option
            ListTile(
              leading: Icon(
                Icons.calendar_month_outlined,
                color: colorScheme.textBase,
              ),
              title: Text(
                "Shift dates and time",
                style: TextStyle(
                  color: colorScheme.textBase,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                "Photos keep relative time difference",
                style: TextStyle(
                  color: colorScheme.textFaint,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.strokeMuted,
              ),
              onTap: () => onShiftDates(),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoDateHeaderWidget extends StatelessWidget {
  const PhotoDateHeaderWidget({
    super.key,
    required this.enteFiles,
    required this.startDate,
    required this.endDate,
  });

  final Iterable<EnteFile> enteFiles;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context) {
    final photoCount = enteFiles.length;
    final colorScheme = getEnteColorScheme(context);
    final locale = Localizations.localeOf(context);
    bool multipleFiles = true;
    if (photoCount == 1) {
      multipleFiles = false;
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: ThumbnailWidget(enteFiles.first),
            ),
          ),
          const SizedBox(width: 16),
          // Photo count and date info
          multipleFiles
              ? Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$photoCount photos",
                        style: TextStyle(
                          color: colorScheme.textBase,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDate(startDate, locale),
                            style: TextStyle(
                              color: colorScheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "-",
                              style: TextStyle(
                                color: colorScheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(endDate, locale),
                            style: TextStyle(
                              color: colorScheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          enteFiles.first.displayName,
                          style: TextStyle(
                            color: colorScheme.textBase,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${DateFormat('EEE, dd MMM yyyy').format(startDate)} · ${DateFormat.Hm(locale.languageCode).format(startDate)}",
                        style: TextStyle(
                          color: colorScheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date, Locale locale) {
  return "${DateFormat('EEE, dd MMM yyyy').format(date)}\n${DateFormat.Hm(locale.languageCode).format(date)}";
}
