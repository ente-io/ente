import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import "package:photos/models/file/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class PhotoDateSelectionBottomSheet extends StatelessWidget {
  final Iterable<EnteFile> enteFiles;
  final Function(bool) onSelectOneDate;
  final Function(bool) onShiftDates;

  const PhotoDateSelectionBottomSheet({
    super.key,
    required this.enteFiles,
    required this.onSelectOneDate,
    required this.onShiftDates,
  });

  @override
  Widget build(BuildContext context) {
    final photoCount = enteFiles.length;
    if (photoCount == 0) {
      return const SizedBox.shrink();
    }
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
        color: getEnteColorScheme(context).backgroundElevated2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo count and date range section
          Container(
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
                        style: const TextStyle(
                          color: Colors.white,
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
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "-",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(endDate),
                            style: TextStyle(
                              color: Colors.grey[400],
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
          ),
          Divider(
            color: Colors.grey[800],
            height: 1,
          ),

          // Select one date option
          ListTile(
            leading: const Icon(
              Icons.calendar_today,
              color: Colors.white,
            ),
            title: const Text(
              "Select one date and time",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              "Move selected photos to one date",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.white,
            ),
            onTap: () => onSelectOneDate(true),
          ),

          // Shift dates option
          ListTile(
            leading: const Icon(
              Icons.calendar_month,
              color: Colors.white,
            ),
            title: const Text(
              "Shift dates and time",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              "Photos keep relative time difference",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.white,
            ),
            onTap: () => onShiftDates(true),
          ),

          // Bottom indicator line
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "Sat, ${DateFormat('dd MMM yyyy').format(date)}\n${DateFormat('h:mm a').format(date)}";
  }
}
