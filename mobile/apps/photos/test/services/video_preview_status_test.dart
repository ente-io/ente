import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/upload_locks_db.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/metadata/file_magic.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/file_magic_service.dart';
import 'package:photos/services/filedata/model/file_data.dart';
import 'package:photos/services/isolated_ffmpeg_service.dart';
import 'package:photos/services/video_preview_service.dart';

import 'video_preview_status_test.mocks.dart';

@GenerateMocks([
  ServiceLocator,
  Configuration,
  FilesDB,
  UploadLocksDB,
  FileMagicService,
  IsolatedFfmpegService,
  Dio,
  DefaultCacheManager,
  CacheManager,
])
void main() {
  late VideoPreviewService videoPreviewService;
  late MockServiceLocator mockServiceLocator;
  late MockConfiguration mockConfiguration;
  late MockFilesDB mockFilesDB;
  late MockUploadLocksDB mockUploadLocksDB;
  late MockFileMagicService mockFileMagicService;
  late MockIsolatedFfmpegService mockFfmpegService;
  late MockDefaultCacheManager mockCacheManager;
  late MockCacheManager mockVideoCacheManager;

  setUp(() {
    mockServiceLocator = MockServiceLocator();
    mockConfiguration = MockConfiguration();
    mockFilesDB = MockFilesDB();
    mockUploadLocksDB = MockUploadLocksDB();
    mockFileMagicService = MockFileMagicService();
    mockFfmpegService = MockIsolatedFfmpegService();
    mockCacheManager = MockDefaultCacheManager();
    mockVideoCacheManager = MockCacheManager();

    videoPreviewService = VideoPreviewService(
      mockConfiguration,
      mockServiceLocator,
      mockFilesDB,
      mockUploadLocksDB,
      mockFileMagicService,
      mockFfmpegService,
      mockCacheManager,
      mockVideoCacheManager,
    );
  });

  group('VideoPreviewService Queue Management', () {
    test('should add file to manual queue successfully', () async {
      // Arrange
      final file = EnteFile()
        ..uploadedFileID = 123
        ..title = 'test_video.mp4'
        ..collectionID = 1;

      when(mockUploadLocksDB.isInStreamQueue(123))
          .thenAnswer((_) async => false);
      when(mockUploadLocksDB.addToStreamQueue(123, any))
          .thenAnswer((_) async => {});

      final result = await videoPreviewService.addToManualQueue(file, 'create');

      // Assert
      expect(result, isTrue);
      verify(mockUploadLocksDB.addToStreamQueue(123, 'create')).called(1);
    });

    test('should not add file already in queue', () async {
      // Arrange
      final file = EnteFile()
        ..uploadedFileID = 123
        ..title = 'test_video.mp4';

      when(mockUploadLocksDB.isInStreamQueue(123))
          .thenAnswer((_) async => true);

      final result = await videoPreviewService.addToManualQueue(file, 'create');

      // Assert
      expect(result, isFalse);
      verifyNever(mockUploadLocksDB.addToStreamQueue(any, any));
    });

    test('should return false for file without uploadedFileID', () async {
      // Arrange
      final file = EnteFile()
        ..title = 'test_video.mp4'
        ..uploadedFileID = null;

      final result = await videoPreviewService.addToManualQueue(file, 'create');

      // Assert
      expect(result, isFalse);
      verifyZeroInteractions(mockUploadLocksDB);
    });

    test('should clear queue properly', () {
      // Arrange
      videoPreviewService.fileQueue[123] = EnteFile()..uploadedFileID = 123;
      videoPreviewService.fileQueue[456] = EnteFile()..uploadedFileID = 456;

      videoPreviewService.clearQueue();

      // Assert
      expect(videoPreviewService.fileQueue.isEmpty, isTrue);
    });

    test('should identify currently processing file', () {
      // Arrange
      videoPreviewService.uploadingFileId = 123;

      expect(videoPreviewService.isCurrentlyProcessing(123), isTrue);
      expect(videoPreviewService.isCurrentlyProcessing(456), isFalse);
      expect(videoPreviewService.isCurrentlyProcessing(null), isFalse);
    });
  });

  group('VideoPreviewService Status Calculation Edge Cases', () {
    test('should handle video files only (no mixed types in calcStatus)',
        () async {
      // Note: calcStatus expects to receive only video files from the DB query
      // Arrange
      final files = [
        EnteFile()
          ..uploadedFileID = 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
        EnteFile()
          ..uploadedFileID = 3
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      ];

      final previewIds = <int, PreviewInfo>{
        1: PreviewInfo(objectId: 'obj1', objectSize: 1000),
      };

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      // Logic: file 1 -> processed, add to both processed {1} and total {1}
      //        file 3 -> not processed, add to total {1,3}
      // Status = 1/2 = 0.5
      expect(status, equals(0.5));
    });

    test('should handle files with zero uploadedFileID', () async {
      // Arrange
      final files = [
        EnteFile()
          ..uploadedFileID = 0
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
        EnteFile()
          ..uploadedFileID = 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      ];

      final previewIds = <int, PreviewInfo>{
        0: PreviewInfo(objectId: 'obj0', objectSize: 1000),
      };

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      expect(status, equals(0.5)); // 1/2 = 0.5
    });

    test('should handle very large preview counts', () async {
      // Arrange - Create 10,000 files scenario
      final files = List.generate(
        10000,
        (index) => EnteFile()
          ..uploadedFileID = index + 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      );

      final previewIds = <int, PreviewInfo>{};
      // Process every 3rd file
      for (int i = 3; i <= 10000; i += 3) {
        previewIds[i] = PreviewInfo(objectId: 'obj$i', objectSize: 1000);
      }

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      // Every 3rd file is processed: 3333 files out of 10000
      expect(status, closeTo(0.3333, 0.0001));
    });

    test('should handle inconsistent preview data', () async {
      // Arrange
      final files = [
        EnteFile()
          ..uploadedFileID = 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      ];

      final previewIds = <int, PreviewInfo>{
        999: PreviewInfo(
          objectId: 'obj999',
          objectSize: 1000,
        ), // Non-existent file
      };

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      expect(status, equals(0.0)); // No matching processed files
    });
  });

  group('VideoPreviewService File Filtering', () {
    test('should handle files with different sv values', () async {
      // Arrange
      final files = [
        EnteFile()
          ..uploadedFileID = 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(sv: 0), // sv=0 (included)
        EnteFile()
          ..uploadedFileID = 2
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(sv: 1), // sv=1 (skipped)
        EnteFile()
          ..uploadedFileID = 3
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(sv: 2), // sv=2 (included)
        EnteFile()
          ..uploadedFileID = 4
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(), // sv=null (included)
      ];

      final previewIds = <int, PreviewInfo>{
        1: PreviewInfo(objectId: 'obj1', objectSize: 1000),
        3: PreviewInfo(objectId: 'obj3', objectSize: 1000),
      };

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      // Files 1, 3, 4 are included (sv != 1), file 2 is skipped
      // Files 1, 3 are processed out of 3 total eligible files
      // Status = 2/3 ≈ 0.6667
      expect(status, closeTo(0.6667, 0.0001));
    });

    test('should handle boundary conditions for processing', () async {
      // Arrange - Test with exactly one file
      final files = [
        EnteFile()
          ..uploadedFileID = 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      ];

      final previewIds = <int, PreviewInfo>{
        1: PreviewInfo(objectId: 'obj1', objectSize: 1000),
      };

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      expect(status, equals(1.0)); // 1/1 = 100%
    });
  });

  group('VideoPreviewService Concurrency Tests', () {
    test('should handle concurrent status calculations', () async {
      // Arrange
      final files = List.generate(
        100,
        (index) => EnteFile()
          ..uploadedFileID = index + 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      );

      final previewIds = <int, PreviewInfo>{};
      for (int i = 1; i <= 50; i++) {
        previewIds[i] = PreviewInfo(objectId: 'obj$i', objectSize: 1000);
      }

      final futures = List.generate(
        5,
        (_) => videoPreviewService.calcStatus(files, previewIds),
      );
      final results = await Future.wait(futures);

      // Assert - All results should be consistent
      for (final result in results) {
        expect(result, equals(0.5)); // 50/100 = 0.5
      }
    });
  });

  group('VideoPreviewService Data Integrity', () {
    test('should handle corrupted preview data gracefully', () async {
      // Arrange
      final files = [
        EnteFile()
          ..uploadedFileID = 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
        EnteFile()
          ..uploadedFileID = 2
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      ];

      // Simulate corrupted preview data with negative IDs
      final previewIds = <int, PreviewInfo>{
        -1: PreviewInfo(objectId: 'corrupt', objectSize: -100),
        1: PreviewInfo(objectId: 'obj1', objectSize: 1000),
      };

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      expect(status, equals(0.5)); // Only file 1 matches and is processed
    });

    test('should maintain precision with floating point calculations',
        () async {
      // Arrange - Test edge case numbers that might cause floating point issues
      final files = List.generate(
        3,
        (index) => EnteFile()
          ..uploadedFileID = index + 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      );

      final previewIds = <int, PreviewInfo>{
        1: PreviewInfo(objectId: 'obj1', objectSize: 1000),
      };

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      // 1/3 should be exactly represented or very close
      expect(status, closeTo(1.0 / 3.0, 0.0000001));
    });
  });

  group('VideoPreviewService Complex Scenarios', () {
    test('should handle real-world mixed scenario', () async {
      // Arrange - Simulate real photo library scenario (only video files)
      final files = [
        // Regular videos
        ...List.generate(
          50,
          (index) => EnteFile()
            ..uploadedFileID = index + 1
            ..fileType = FileType.video
            ..pubMagicMetadata = PubMagicMetadata(),
        ),

        // Videos with sv=1 (should be skipped)
        ...List.generate(
          10,
          (index) => EnteFile()
            ..uploadedFileID = index + 51
            ..fileType = FileType.video
            ..pubMagicMetadata = PubMagicMetadata(sv: 1),
        ),

        // Videos with null metadata
        ...List.generate(
          5,
          (index) => EnteFile()
            ..uploadedFileID = index + 61
            ..fileType = FileType.video
            ..pubMagicMetadata = null,
        ),
      ];

      // Process 30 regular videos and 2 null-metadata videos
      final previewIds = <int, PreviewInfo>{};
      for (int i = 1; i <= 30; i++) {
        previewIds[i] = PreviewInfo(objectId: 'obj$i', objectSize: 1000);
      }
      previewIds[62] = PreviewInfo(objectId: 'obj62', objectSize: 1000);
      previewIds[64] = PreviewInfo(objectId: 'obj64', objectSize: 1000);

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      // Total eligible: 50 regular + 5 null-metadata = 55 videos (sv=1 files are skipped)
      // Processed: 30 regular + 2 null-metadata = 32 videos
      // Logic: processed files go to both processed and total sets
      //        unprocessed files (except sv=1) go to total set only
      // So: processed = {1..30, 62, 64}, total = {1..50, 61..65}
      // Status = 32/55 ≈ 0.5818
      expect(status, closeTo(32.0 / 55.0, 0.0001));
    });

    test('should handle progressive processing simulation', () async {
      // Arrange
      final files = List.generate(
        10,
        (index) => EnteFile()
          ..uploadedFileID = index + 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      );

      for (int processed = 0; processed <= 10; processed++) {
        final previewIds = <int, PreviewInfo>{};
        for (int i = 1; i <= processed; i++) {
          previewIds[i] = PreviewInfo(objectId: 'obj$i', objectSize: 1000);
        }

        final status = await videoPreviewService.calcStatus(files, previewIds);
        final expectedStatus = processed / 10.0;

        expect(
          status,
          equals(expectedStatus),
          reason: 'Failed at $processed processed files',
        );
      }
    });
  });

  group('VideoPreviewService Performance Edge Cases', () {
    test('should handle empty preview IDs efficiently', () async {
      // Arrange
      final files = List.generate(
        1000,
        (index) => EnteFile()
          ..uploadedFileID = index + 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      );

      final emptyPreviewIds = <int, PreviewInfo>{};

      final stopwatch = Stopwatch()..start();
      final status =
          await videoPreviewService.calcStatus(files, emptyPreviewIds);
      stopwatch.stop();

      // Assert
      expect(status, equals(0.0));
      // Should complete quickly even with 1000 files
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should handle all-processed scenario efficiently', () async {
      // Arrange
      final files = List.generate(
        1000,
        (index) => EnteFile()
          ..uploadedFileID = index + 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      );

      final allProcessedIds = <int, PreviewInfo>{};
      for (int i = 1; i <= 1000; i++) {
        allProcessedIds[i] = PreviewInfo(objectId: 'obj$i', objectSize: 1000);
      }

      final stopwatch = Stopwatch()..start();
      final status =
          await videoPreviewService.calcStatus(files, allProcessedIds);
      stopwatch.stop();

      // Assert
      expect(status, equals(1.0));
      // Should complete quickly even with all files processed
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('VideoPreviewService Status Boundary Conditions', () {
    test('should clamp status between 0 and 1', () async {
      // This test verifies that the clamp function works as expected
      // even though we don't expect values outside [0,1] in normal cases

      // Arrange - Normal case that should result in valid percentage
      final files = [
        EnteFile()
          ..uploadedFileID = 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      ];

      final previewIds = <int, PreviewInfo>{
        1: PreviewInfo(objectId: 'obj1', objectSize: 1000),
      };

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      expect(status, greaterThanOrEqualTo(0.0));
      expect(status, lessThanOrEqualTo(1.0));
    });

    test('should handle duplicate uploadedFileIDs consistently', () async {
      // Arrange - This shouldn't happen in practice, but test robustness
      final files = [
        EnteFile()
          ..uploadedFileID = 1
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
        EnteFile()
          ..uploadedFileID = 1 // Duplicate ID
          ..fileType = FileType.video
          ..pubMagicMetadata = PubMagicMetadata(),
      ];

      final previewIds = <int, PreviewInfo>{
        1: PreviewInfo(objectId: 'obj1', objectSize: 1000),
      };

      final status = await videoPreviewService.calcStatus(files, previewIds);

      // Assert
      // Sets should handle duplicates naturally
      expect(status, equals(1.0)); // 1/1 = 100%
    });
  });
}
