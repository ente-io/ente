import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/ml/db.dart';
import 'package:photos/events/faces_timeline_ready_event.dart';
import 'package:photos/models/faces_through_time/face_timeline.dart';
import 'package:photos/models/faces_through_time/face_timeline_entry.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/services/machine_learning/face_ml/person/person_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacesThroughTimeService {
  static final _logger = Logger('FacesThroughTimeService');
  static const _minYearSpan = 7;
  static const _photosPerYear = 4;
  static const _minFaceScore = 0.85;

  static FacesThroughTimeService? _instance;
  factory FacesThroughTimeService() =>
      _instance ??= FacesThroughTimeService._();
  FacesThroughTimeService._();

  Future<bool> isEligible(String personId) async {
    try {
      // Get all file IDs for this person
      final fileIds = await MLDataDB.instance.getPersonFileIds(personId);
      if (fileIds.isEmpty) return false;

      // Get file creation times from FilesDB
      final files = await FilesDB.instance.getFilesFromIDs(fileIds);
      if (files.isEmpty) return false;

      // Group files by year
      final filesByYear = <int, List<EnteFile>>{};
      for (final file in files) {
        if (file.creationTime == null) continue;
        final year =
            DateTime.fromMillisecondsSinceEpoch(file.creationTime!).year;
        filesByYear.putIfAbsent(year, () => []).add(file);
      }

      // Check if we have enough years with enough photos
      final years = filesByYear.keys.toList()..sort();
      if (years.isEmpty) return false;

      // Check for consecutive years with enough photos
      int consecutiveYears = 0;
      int maxConsecutive = 0;

      for (int i = 0; i < years.length; i++) {
        if (filesByYear[years[i]]!.length >= _photosPerYear) {
          if (i == 0 || years[i] == years[i - 1] + 1) {
            consecutiveYears++;
            maxConsecutive = consecutiveYears > maxConsecutive
                ? consecutiveYears
                : maxConsecutive;
          } else {
            consecutiveYears = 1;
          }
        } else {
          consecutiveYears = 0;
        }
      }

      return maxConsecutive >= _minYearSpan;
    } catch (e) {
      _logger.severe('Error checking eligibility', e);
      return false;
    }
  }

  Future<bool> hasBeenViewed(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('faces_timeline_viewed_$personId') ?? false;
  }

  Future<void> markAsViewed(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('faces_timeline_viewed_$personId', true);
  }

  Future<FaceTimeline?> checkAndPrepareTimeline(String personId) async {
    if (!await isEligible(personId)) return null;

    // Check cache
    final cached = await _loadFromCache(personId);
    if (cached != null && cached.isValid) {
      return cached;
    }

    // Generate new timeline
    final timeline = await _generateTimeline(personId);
    if (timeline != null) {
      await _saveToCache(timeline);
      // Note: Thumbnail generation will be done asynchronously
      unawaited(_generateThumbnailsAsync(timeline));

      // Notify UI when ready
      Bus.instance.fire(FacesTimelineReadyEvent(personId));
    }

    return timeline;
  }

  Future<FaceTimeline?> getTimeline(String personId) async {
    // First check cache
    final cached = await _loadFromCache(personId);
    if (cached != null && cached.isValid) {
      return cached;
    }

    // Generate if not cached
    return await _generateTimeline(personId);
  }

  Future<FaceTimeline?> _generateTimeline(String personId) async {
    try {
      // Get high quality faces
      final faces = await MLDataDB.instance
          .getPersonFacesWithScores(personId, _minFaceScore);
      if (faces.isEmpty) return null;

      // Get file IDs
      final fileIds = faces.map((f) => f['fileId'] as int).toSet().toList();

      // Get files with creation times
      final files = await FilesDB.instance.getFilesFromIDs(fileIds);
      final fileMap = Map.fromEntries(
        files.map((f) => MapEntry(f.uploadedFileID ?? f.generatedID!, f)),
      );

      // Get person info
      final person = await PersonService.instance.getPerson(personId);

      // Group faces by year
      final facesByYear = <int, List<Map<String, dynamic>>>{};
      for (final face in faces) {
        final file = fileMap[face['fileId']];
        if (file == null || file.creationTime == null) continue;

        final timestamp =
            DateTime.fromMillisecondsSinceEpoch(file.creationTime!);
        final year = timestamp.year;

        // Apply age filter if DOB available
        if (person?.data.birthDate != null) {
          final dob = DateTime.parse(person!.data.birthDate!);
          final age = timestamp.difference(dob).inDays / 365.25;
          if (age <= 4.0) continue;
        }

        face['timestamp'] = timestamp;
        face['file'] = file;
        facesByYear.putIfAbsent(year, () => []).add(face);
      }

      // Select faces using quantile approach
      final selectedEntries = <FaceTimelineEntry>[];
      for (final year in facesByYear.keys.toList()..sort()) {
        final yearFaces = facesByYear[year]!;
        if (yearFaces.length < _photosPerYear) continue;

        // Sort by timestamp
        yearFaces.sort(
          (a, b) => (a['timestamp'] as DateTime)
              .compareTo(b['timestamp'] as DateTime),
        );

        // Select at 1st, 25th, 50th, 75th percentiles
        final indices = [
          0,
          (yearFaces.length * 0.25).floor(),
          (yearFaces.length * 0.50).floor(),
          (yearFaces.length * 0.75).floor(),
        ];

        for (final idx in indices) {
          final face = yearFaces[idx];
          final timestamp = face['timestamp'] as DateTime;

          selectedEntries.add(
            FaceTimelineEntry(
              faceId: face['faceId'] as String,
              fileId: face['fileId'] as int,
              timestamp: timestamp,
              ageText: _calculateAgeText(
                timestamp,
                person?.data.birthDate != null
                    ? DateTime.parse(person!.data.birthDate!)
                    : null,
              ),
              relativeTimeText: _calculateRelativeTime(timestamp),
            ),
          );
        }
      }

      if (selectedEntries.length < 28) return null;

      return FaceTimeline(
        personId: personId,
        entries: selectedEntries,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.severe('Error generating timeline', e);
      return null;
    }
  }

  Future<void> _generateThumbnailsAsync(FaceTimeline timeline) async {
    // This will be implemented once we understand the face thumbnail system better
    _logger.info('Thumbnail generation for timeline will be implemented');
  }

  String? _calculateAgeText(DateTime photoTime, DateTime? dob) {
    if (dob == null) return null;

    final diff = photoTime.difference(dob);
    final years = (diff.inDays / 365.25).floor();
    final months = ((diff.inDays % 365.25) / 30).floor();

    if (photoTime.year == DateTime.now().year) {
      // Current year - show relative time
      final monthsAgo = DateTime.now().difference(photoTime).inDays ~/ 30;
      if (monthsAgo == 0) return 'Recently';
      return '$monthsAgo months ago';
    }

    if (months > 0) {
      return 'Age $years years $months months';
    }
    return 'Age $years years';
  }

  String _calculateRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays < 30) return 'Recently';
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months months ago';
    }

    final years = (diff.inDays / 365.25).floor();
    return '$years years ago';
  }

  Future<String> _getCachePath(String personId) async {
    final dir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${dir.path}/cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return '${cacheDir.path}/faces_timeline_$personId.json';
  }

  Future<FaceTimeline?> _loadFromCache(String personId) async {
    try {
      final path = await _getCachePath(personId);
      final file = File(path);
      if (!await file.exists()) return null;

      final json = jsonDecode(await file.readAsString());
      return FaceTimeline.fromJson(json);
    } catch (e) {
      _logger.warning('Failed to load cache', e);
      return null;
    }
  }

  Future<void> _saveToCache(FaceTimeline timeline) async {
    try {
      final path = await _getCachePath(timeline.personId);
      final file = File(path);
      await file.writeAsString(jsonEncode(timeline.toJson()));
    } catch (e) {
      _logger.warning('Failed to save cache', e);
    }
  }

  Future<void> clearCache(String personId) async {
    try {
      final path = await _getCachePath(personId);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      _logger.warning('Failed to clear cache', e);
    }
  }
}