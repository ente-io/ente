import 'package:flutter_test/flutter_test.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/ignored_file.dart';
import 'package:photos/services/ignored_files_service.dart';

void main() {
  group('IgnoredFilesService optimized copy reason', () {
    final service = IgnoredFilesService.instance;

    EnteFile buildFile({required String localId}) {
      return EnteFile()
        ..localID = localId
        ..title = 'sample.jpg'
        ..deviceFolder = 'DCIM/Camera';
    }

    test('returns optimized_copy as upload skip reason', () {
      final file = buildFile(localId: 'local-1');
      final map = <String, String>{'local-1': kIgnoreReasonOptimizedCopy};

      final reason = service.getUploadSkipReason(map, file);

      expect(reason, kIgnoreReasonOptimizedCopy);
    });

    test('marks optimized copy as skipped upload', () {
      final file = buildFile(localId: 'local-2');
      final map = <String, String>{'local-2': kIgnoreReasonOptimizedCopy};

      final shouldSkip = service.shouldSkipUpload(map, file);

      expect(shouldSkip, isTrue);
    });

    test('does not skip when id is missing from ignore map', () {
      final file = buildFile(localId: 'local-3');
      final map = <String, String>{'some-other-id': kIgnoreReasonOptimizedCopy};

      final shouldSkip = service.shouldSkipUpload(map, file);
      final reason = service.getUploadSkipReason(map, file);

      expect(shouldSkip, isFalse);
      expect(reason, isNull);
    });
  });
}
