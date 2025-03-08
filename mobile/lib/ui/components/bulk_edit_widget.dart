import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import "package:photos/models/file/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class BulkEditDateBottomSheet extends StatelessWidget {
  final Iterable<EnteFile> enteFiles;

  const BulkEditDateBottomSheet({
    super.key,
    required this.enteFiles,
  });

  @override
  Widget build(BuildContext context) {
    final photoCount = enteFiles.length;
    if (photoCount == 0) {
      return const SizedBox.shrink();
    }
    final colorScheme = getEnteColorScheme(context);
    final firstFileTime =
        DateTime.fromMicrosecondsSinceEpoch(enteFiles.first.creationTime!);
    DateTime startDate = firstFileTime;
    DateTime endDate = firstFileTime;
    for (final file in enteFiles) {
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
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo count and date range section
          PhotoDateHeaderWidget(
            enteFiles: enteFiles,
            startDate: startDate,
            endDate: endDate,
          ),
          SelectDateOrShiftWidget(
            onSelectOneDate: () {
              Navigator.pop(context);
            },
            onShiftDates: () {
              Navigator.pop(context);
            },
          ),

          // Bottom indicator line
          const SizedBox(height: 48),
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
      padding: const EdgeInsets.all(8.0),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: colorScheme.blurStrokeFaint,
              ),
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
    if (photoCount == 0) {
      return const SizedBox.shrink();
    }
    final colorScheme = getEnteColorScheme(context);
    if (photoCount == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Expanded(
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
                      _formatDate(startDate),
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
                      _formatDate(endDate),
                      style: TextStyle(
                        color: colorScheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return "Sat, ${DateFormat('dd MMM yyyy').format(date)}\n${DateFormat('h:mm a').format(date)}";
}
