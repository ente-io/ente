# Faces Through Time - Complete Implementation Guide

## Overview

This document provides the complete implementation guide for the Faces Through Time feature, including all components, database queries, UI elements, and video generation using FFmpeg.

## Complete File Structure

```
mobile/apps/photos/lib/
├── services/
│   ├── faces_through_time_service.dart          [NEW]
│   └── faces_through_time_video_service.dart    [NEW]
├── models/
│   └── faces_through_time/
│       ├── face_timeline.dart                   [NEW]
│       └── face_timeline_entry.dart             [NEW]
├── ui/
│   └── viewer/
│       └── people/
│           ├── people_page.dart                 [MODIFY]
│           ├── faces_through_time_page.dart     [NEW]
│           └── faces_timeline_banner.dart       [NEW]
├── events/
│   └── faces_timeline_ready_event.dart          [NEW]
└── db/
    └── ml/
        └── person_db.dart                        [MODIFY]
```

## 1. Data Models

### face_timeline.dart
```dart
// lib/models/faces_through_time/face_timeline.dart
import 'dart:convert';

class FaceTimeline {
  final String personId;
  final List<FaceTimelineEntry> entries;
  final DateTime generatedAt;
  final bool hasBeenViewed;
  final int version;

  FaceTimeline({
    required this.personId,
    required this.entries,
    required this.generatedAt,
    this.hasBeenViewed = false,
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
    'personId': personId,
    'generatedAt': generatedAt.toIso8601String(),
    'faceIds': entries.map((e) => e.faceId).toList(),
    'hasBeenViewed': hasBeenViewed,
    'version': version,
  };

  factory FaceTimeline.fromJson(Map<String, dynamic> json) {
    return FaceTimeline(
      personId: json['personId'],
      entries: (json['faceIds'] as List)
          .map((id) => FaceTimelineEntry(faceId: id))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt']),
      hasBeenViewed: json['hasBeenViewed'] ?? false,
      version: json['version'] ?? 1,
    );
  }
}
```

### face_timeline_entry.dart
```dart
// lib/models/faces_through_time/face_timeline_entry.dart
import 'dart:typed_data';

class FaceTimelineEntry {
  final String faceId;
  final int fileId;
  final DateTime timestamp;
  final String? ageText;
  final String? relativeTimeText;
  final Uint8List? thumbnail;

  FaceTimelineEntry({
    required this.faceId,
    this.fileId = 0,
    DateTime? timestamp,
    this.ageText,
    this.relativeTimeText,
    this.thumbnail,
  }) : timestamp = timestamp ?? DateTime.now();

  String get displayText => ageText ?? relativeTimeText ?? '';
}
```

## 2. Core Service Implementation

### faces_through_time_service.dart
```dart
// lib/services/faces_through_time_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/ml/person_db.dart';
import 'package:photos/events/faces_timeline_ready_event.dart';
import 'package:photos/models/faces_through_time/face_timeline.dart';
import 'package:photos/models/faces_through_time/face_timeline_entry.dart';
import 'package:photos/models/ml/face/person.dart';
import 'package:photos/utils/face/face_thumbnail_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacesThroughTimeService {
  static final _logger = Logger('FacesThroughTimeService');
  static const _minYearSpan = 7;
  static const _photosPerYear = 4;
  static const _minFaceScore = 0.85;
  static const _minAge = 5.0;
  static const _cacheValidityDays = 365;
  static const _maxConcurrentThumbnails = 4;

  static FacesThroughTimeService? _instance;
  factory FacesThroughTimeService() => _instance ??= FacesThroughTimeService._();
  FacesThroughTimeService._();

  Future<bool> isEligible(String personId) async {
    try {
      final yearSpan = await PersonDB.instance.getPersonPhotoYearSpan(personId);
      if (yearSpan < _minYearSpan) return false;

      final faces = await PersonDB.instance.getPersonHighQualityFaces(
        personId,
        _minFaceScore,
      );

      // Check if we have enough faces per year
      final facesByYear = <int, List<dynamic>>{};
      for (final face in faces) {
        final year = face['timestamp'].year;
        facesByYear.putIfAbsent(year, () => []).add(face);
      }

      // Need at least 7 consecutive years with 4+ photos each
      int consecutiveYears = 0;
      int maxConsecutive = 0;
      
      final years = facesByYear.keys.toList()..sort();
      for (int i = 0; i < years.length; i++) {
        if (facesByYear[years[i]]!.length >= _photosPerYear) {
          if (i == 0 || years[i] == years[i - 1] + 1) {
            consecutiveYears++;
            maxConsecutive = consecutiveYears > maxConsecutive 
                ? consecutiveYears : maxConsecutive;
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
    if (cached != null && _isCacheValid(cached)) {
      return cached;
    }

    // Generate new timeline
    final timeline = await _generateTimeline(personId);
    if (timeline != null) {
      await _saveToCache(timeline);
      await _generateThumbnails(timeline);
      
      // Notify UI when ready
      Bus.instance.fire(FacesTimelineReadyEvent(personId));
    }

    return timeline;
  }

  Future<FaceTimeline?> _generateTimeline(String personId) async {
    try {
      final faces = await PersonDB.instance.getPersonHighQualityFaces(
        personId,
        _minFaceScore,
      );

      // Group by year and select using quantiles
      final facesByYear = <int, List<dynamic>>{};
      for (final face in faces) {
        final year = face['timestamp'].year;
        
        // Apply age filter if DOB available
        if (face['dob'] != null) {
          final age = face['timestamp'].difference(face['dob']).inDays / 365.25;
          if (age <= 4.0) continue;
        }
        
        facesByYear.putIfAbsent(year, () => []).add(face);
      }

      // Select faces using quantile approach
      final selectedEntries = <FaceTimelineEntry>[];
      for (final year in facesByYear.keys.toList()..sort()) {
        final yearFaces = facesByYear[year]!;
        if (yearFaces.length < _photosPerYear) continue;

        // Sort by timestamp
        yearFaces.sort((a, b) => 
          a['timestamp'].compareTo(b['timestamp']));

        // Select at 1st, 25th, 50th, 75th percentiles
        final indices = [
          0,
          (yearFaces.length * 0.25).floor(),
          (yearFaces.length * 0.50).floor(),
          (yearFaces.length * 0.75).floor(),
        ];

        for (final idx in indices) {
          final face = yearFaces[idx];
          selectedEntries.add(FaceTimelineEntry(
            faceId: face['faceId'],
            fileId: face['fileId'],
            timestamp: face['timestamp'],
            ageText: _calculateAgeText(face['timestamp'], face['dob']),
            relativeTimeText: _calculateRelativeTime(face['timestamp']),
          ));
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

  Future<void> _generateThumbnails(FaceTimeline timeline) async {
    // Generate thumbnails in batches
    for (int i = 0; i < timeline.entries.length; i += _maxConcurrentThumbnails) {
      final batch = timeline.entries.skip(i).take(_maxConcurrentThumbnails);
      
      await Future.wait(batch.map((entry) async {
        try {
          // Use existing face thumbnail generation
          final file = await _getFileForFace(entry.faceId);
          final face = await _getFaceData(entry.faceId);
          
          final cropMap = await getCachedFaceCrops(
            file,
            [face],
            useFullFile: true,
            useTempCache: false,
          );
          
          entry.thumbnail = cropMap[face.faceID];
        } catch (e) {
          _logger.warning('Failed to generate thumbnail for ${entry.faceId}', e);
        }
      }));
    }
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
    return '${dir.path}/cache/faces_timeline_$personId.json';
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
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(timeline.toJson()));
    } catch (e) {
      _logger.warning('Failed to save cache', e);
    }
  }

  bool _isCacheValid(FaceTimeline timeline) {
    final age = DateTime.now().difference(timeline.generatedAt);
    return age.inDays < _cacheValidityDays;
  }
}
```

## 3. Video Generation Service

### faces_through_time_video_service.dart
```dart
// lib/services/faces_through_time_video_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/models/faces_through_time/face_timeline_entry.dart';
import 'package:share_plus/share_plus.dart';

class FacesThroughTimeVideoService {
  static final _logger = Logger('FacesThroughTimeVideoService');
  static const _videoFrameDuration = 1; // seconds
  static const _watermarkText = 'Created with Ente Photos';

  Future<void> generateAndShareVideo(
    List<FaceTimelineEntry> entries,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${tempDir.path}/faces_timeline_$timestamp.mp4';
    
    try {
      // Create input file list for FFmpeg
      final listFile = File('${tempDir.path}/input_$timestamp.txt');
      final frameFiles = <File>[];
      
      // Write each thumbnail as a temporary image file
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        if (entry.thumbnail == null) continue;
        
        final frameFile = File('${tempDir.path}/frame_${timestamp}_$i.jpg');
        await frameFile.writeAsBytes(entry.thumbnail!);
        frameFiles.add(frameFile);
        
        // Add to input list with duration
        await listFile.writeAsString(
          "file '${frameFile.path}'\nduration $_videoFrameDuration\n",
          mode: FileMode.append,
        );
      }
      
      // Add last frame again (FFmpeg requirement)
      if (frameFiles.isNotEmpty) {
        await listFile.writeAsString(
          "file '${frameFiles.last.path}'\n",
          mode: FileMode.append,
        );
      }
      
      // Build FFmpeg command with text overlay
      final textOverlays = _buildTextOverlayFilter(entries);
      final watermarkFilter = _buildWatermarkFilter();
      
      final command = '-f concat -safe 0 -i "${listFile.path}" '
          '-vf "$textOverlays,$watermarkFilter" '
          '-c:v libx264 -preset medium -crf 23 '
          '-pix_fmt yuv420p -movflags +faststart '
          '"$outputPath"';
      
      _logger.info('Executing FFmpeg command: $command');
      
      // Execute FFmpeg
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        // Share the video
        await Share.shareXFiles(
          [XFile(outputPath)],
          text: 'Check out this amazing face timeline!',
        );
      } else {
        final output = await session.getOutput();
        throw Exception('Video generation failed: $output');
      }
    } catch (e) {
      _logger.severe('Error generating video', e);
      rethrow;
    } finally {
      // Cleanup temp files
      try {
        final dir = Directory('${tempDir.path}');
        final files = dir.listSync()
            .where((f) => f.path.contains(timestamp.toString()));
        for (final file in files) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  String _buildTextOverlayFilter(List<FaceTimelineEntry> entries) {
    // Create dynamic text that changes with each frame
    final textCommands = <String>[];
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final text = entry.displayText.replaceAll("'", "\\'");
      final startTime = i * _videoFrameDuration;
      final endTime = (i + 1) * _videoFrameDuration;
      
      textCommands.add(
        "drawtext=text='$text':"
        "fontcolor=white:fontsize=30:"
        "box=1:boxcolor=black@0.5:boxborderw=5:"
        "x=(w-text_w)/2:y=h-th-80:"
        "enable='between(t,$startTime,$endTime)'"
      );
    }
    
    return textCommands.join(',');
  }

  String _buildWatermarkFilter() {
    return "drawtext=text='$_watermarkText':"
        "fontcolor=white@0.7:fontsize=20:"
        "x=w-tw-10:y=h-th-10";
  }
}
```

## 4. UI Components

### faces_timeline_banner.dart
```dart
// lib/ui/viewer/people/faces_timeline_banner.dart
import 'package:flutter/material.dart';
import 'package:photos/models/ml/face/person.dart';
import 'package:photos/theme/ente_theme.dart';

class FacesTimelineBanner extends StatelessWidget {
  final PersonEntity person;
  final VoidCallback onTap;

  const FacesTimelineBanner({
    Key? key,
    required this.person,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primary700,
              theme.primary500,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowBase,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: theme.textInverse,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How ${person.data.name} grew over the years',
                    style: TextStyle(
                      color: theme.textInverse,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to see their journey',
                    style: TextStyle(
                      color: theme.textInverse.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.textInverse,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
```

### faces_through_time_page.dart
```dart
// lib/ui/viewer/people/faces_through_time_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photos/models/faces_through_time/face_timeline.dart';
import 'package:photos/models/faces_through_time/face_timeline_entry.dart';
import 'package:photos/services/faces_through_time_service.dart';
import 'package:photos/services/faces_through_time_video_service.dart';
import 'package:photos/theme/ente_theme.dart';

class FacesThroughTimePage extends StatefulWidget {
  final String personId;
  final String personName;

  const FacesThroughTimePage({
    Key? key,
    required this.personId,
    required this.personName,
  }) : super(key: key);

  @override
  State<FacesThroughTimePage> createState() => _FacesThroughTimePageState();
}

class _FacesThroughTimePageState extends State<FacesThroughTimePage> {
  static const _slideshowInterval = Duration(seconds: 2);
  
  FaceTimeline? _timeline;
  int _currentIndex = 0;
  Timer? _autoAdvanceTimer;
  bool _isPaused = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTimeline() async {
    final service = FacesThroughTimeService();
    final timeline = await service.checkAndPrepareTimeline(widget.personId);
    
    if (timeline != null) {
      setState(() {
        _timeline = timeline;
        _isLoading = false;
      });
      
      await service.markAsViewed(widget.personId);
      _startAutoAdvance();
    }
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (!_isPaused && _timeline != null) {
      _autoAdvanceTimer = Timer.periodic(_slideshowInterval, (_) {
        if (_currentIndex < _timeline!.entries.length - 1) {
          setState(() {
            _currentIndex++;
          });
        } else {
          _autoAdvanceTimer?.cancel();
        }
      });
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    
    if (_isPaused) {
      _autoAdvanceTimer?.cancel();
    } else {
      _startAutoAdvance();
    }
  }

  void _navigateTo(int index) {
    if (index >= 0 && index < _timeline!.entries.length) {
      setState(() {
        _currentIndex = index;
      });
      _startAutoAdvance();
    }
  }

  Future<void> _shareVideo() async {
    if (_timeline == null) return;
    
    setState(() {
      _isPaused = true;
    });
    _autoAdvanceTimer?.cancel();
    
    try {
      final videoService = FacesThroughTimeVideoService();
      await videoService.generateAndShareVideo(_timeline!.entries);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate video: $e')),
      );
    } finally {
      setState(() {
        _isPaused = false;
      });
      _startAutoAdvance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.backgroundElevated,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_timeline == null || _timeline!.entries.isEmpty) {
      return Scaffold(
        backgroundColor: theme.backgroundElevated,
        body: Center(
          child: Text(
            'No timeline available',
            style: TextStyle(color: theme.textMuted),
          ),
        ),
      );
    }
    
    final currentEntry = _timeline!.entries[_currentIndex];
    
    return Scaffold(
      backgroundColor: theme.backgroundElevated,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          final tapX = details.globalPosition.dx;
          
          if (tapX < width * 0.3) {
            // Tap on left - previous
            _navigateTo(_currentIndex - 1);
          } else if (tapX > width * 0.7) {
            // Tap on right - next
            _navigateTo(_currentIndex + 1);
          } else {
            // Tap in center - pause/resume
            _togglePause();
          }
        },
        onLongPressStart: (_) {
          setState(() {
            _isPaused = true;
          });
          _autoAdvanceTimer?.cancel();
        },
        onLongPressEnd: (_) {
          setState(() {
            _isPaused = false;
          });
          _startAutoAdvance();
        },
        child: Stack(
          children: [
            // Face display
            Center(
              child: currentEntry.thumbnail != null
                  ? Image.memory(
                      currentEntry.thumbnail!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    )
                  : Container(
                      width: 200,
                      height: 200,
                      color: theme.fillFaint,
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: theme.textMuted,
                      ),
                    ),
            ),
            
            // Top controls
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textBase),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: theme.textBase),
                    onPressed: _shareVideo,
                  ),
                ],
              ),
            ),
            
            // Bottom info
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.backgroundElevated.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentEntry.displayText,
                    style: TextStyle(
                      color: theme.textBase,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            
            // Progress indicator
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _timeline!.entries.length,
                backgroundColor: theme.fillFaint,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary500),
              ),
            ),
            
            // Pause indicator
            if (_isPaused)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.backgroundElevated.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pause,
                    size: 40,
                    color: theme.textBase,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

## 5. Database Extensions

### person_db.dart modifications
```dart
// Add to lib/db/ml/person_db.dart

Future<int> getPersonPhotoYearSpan(String personId) async {
  final db = await database;
  final result = await db.rawQuery('''
    SELECT 
      (MAX(f.creation_time) - MIN(f.creation_time)) / 31536000000 as year_span
    FROM $filesTable f
    JOIN $facesTable fc ON f.generated_id = fc.file_id
    WHERE fc.person_id = ?
  ''', [personId]);
  
  return (result.first['year_span'] as num?)?.toInt() ?? 0;
}

Future<List<Map<String, dynamic>>> getPersonHighQualityFaces(
  String personId,
  double minScore,
) async {
  final db = await database;
  final results = await db.rawQuery('''
    SELECT 
      fc.face_id as faceId,
      fc.file_id as fileId,
      fc.score,
      fc.blur,
      f.creation_time,
      p.date_of_birth as dob
    FROM $facesTable fc
    JOIN $filesTable f ON fc.file_id = f.generated_id
    LEFT JOIN $personTable p ON p.person_id = fc.person_id
    WHERE fc.person_id = ? AND fc.score >= ?
    ORDER BY f.creation_time ASC
  ''', [personId, minScore]);
  
  return results.map((row) {
    return {
      'faceId': row['faceId'],
      'fileId': row['fileId'],
      'score': row['score'],
      'blur': row['blur'],
      'timestamp': DateTime.fromMillisecondsSinceEpoch(row['creation_time'] as int),
      'dob': row['dob'] != null 
          ? DateTime.parse(row['dob'] as String)
          : null,
    };
  }).toList();
}
```

## 6. PeoplePage Integration

### people_page.dart modifications
```dart
// Add to lib/ui/viewer/people/people_page.dart

class _PeoplePageState extends State<PeoplePage> {
  bool _timelineReady = false;
  bool _timelineViewed = false;
  
  @override
  void initState() {
    super.initState();
    _checkFacesTimeline();
    
    // Listen for timeline ready events
    Bus.instance.on<FacesTimelineReadyEvent>().listen((event) {
      if (event.personId == widget.person.remoteID) {
        setState(() {
          _timelineReady = true;
        });
      }
    });
  }
  
  Future<void> _checkFacesTimeline() async {
    if (widget.person == null) return;
    
    final service = FacesThroughTimeService();
    final isEligible = await service.isEligible(widget.person.remoteID);
    
    if (isEligible) {
      _timelineViewed = await service.hasBeenViewed(widget.person.remoteID);
      
      if (!_timelineViewed) {
        // Start preparing timeline in background
        service.checkAndPrepareTimeline(widget.person.remoteID);
      } else {
        setState(() {
          _timelineReady = true;
        });
      }
    }
  }
  
  void _openTimeline() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FacesThroughTimePage(
          personId: widget.person.remoteID,
          personName: widget.person.data.name,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person.data.name),
        actions: [
          if (_timelineReady && _timelineViewed)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'timeline') {
                  _openTimeline();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'timeline',
                  child: Text('Show face timeline'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (_timelineReady && !_timelineViewed)
            FacesTimelineBanner(
              person: widget.person,
              onTap: _openTimeline,
            ),
          // Rest of the page content
        ],
      ),
    );
  }
}
```

## 7. Event System

### faces_timeline_ready_event.dart
```dart
// lib/events/faces_timeline_ready_event.dart
class FacesTimelineReadyEvent {
  final String personId;
  
  FacesTimelineReadyEvent(this.personId);
}
```

## Step-by-Step Implementation Plan

### Day 1: Database & Models
1. Create model classes (FaceTimeline, FaceTimelineEntry)
2. Add database query methods to PersonDB
3. Test database queries with sample data

### Day 2: Core Service
1. Implement FacesThroughTimeService
2. Add eligibility checking logic
3. Implement quantile-based face selection
4. Add JSON caching mechanism

### Day 3: Thumbnail Generation
1. Integrate with existing face thumbnail cache
2. Implement batch processing
3. Add memory management

### Day 4: UI Components
1. Create FacesTimelineBanner widget
2. Implement FacesThroughTimePage
3. Add tap controls and auto-advance
4. Integrate with PeoplePage

### Day 5: Video Generation
1. Implement FacesThroughTimeVideoService
2. Add FFmpeg command building
3. Test video generation with text overlays
4. Integrate system share sheet

### Day 6: Testing & Polish
1. Test with various photo counts and year spans
2. Verify age filtering works correctly
3. Test video generation and sharing
4. Performance optimization
5. Error handling and edge cases

## Testing Checklist

- [ ] Eligibility checking with edge cases
- [ ] Face selection algorithm correctness
- [ ] Cache persistence and invalidation
- [ ] Banner display logic
- [ ] Slideshow controls (tap, pause, navigate)
- [ ] Age text calculation with/without DOB
- [ ] Video generation with overlays
- [ ] Share functionality
- [ ] Memory usage with large timelines
- [ ] Error recovery for missing thumbnails

## Performance Guidelines

1. **Background Processing**: All heavy computation off main thread
2. **Progressive Loading**: Load thumbnails as needed
3. **Memory Management**: Keep max 5 thumbnails in memory
4. **Cache Strategy**: 1-year validity, JSON format
5. **Batch Processing**: Max 4 concurrent thumbnail generations

## Implementation Complete

This implementation guide provides everything needed to build the Faces Through Time feature. The modular design allows for easy testing and maintenance, while the integration with existing infrastructure ensures consistency with the rest of the app.