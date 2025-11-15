import 'package:flutter_test/flutter_test.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/services/sync/remote_sync_service.dart';

void main() {
  test("only new filter ignores files before threshold", () {
    final service = RemoteSyncService.instance;
    final files = [
      EnteFile()..creationTime = 10,
      EnteFile()..creationTime = 20,
      EnteFile()..creationTime = null,
    ];

    final filtered = service.filterFilesBasedOnOnlyNew(files, 15);

    expect(filtered.length, 1);
    expect(filtered.first.creationTime, 20);
  });

  test("only new filter returns same list when disabled", () {
    final service = RemoteSyncService.instance;
    final files = [
      EnteFile()..creationTime = 5,
      EnteFile()..creationTime = 10,
    ];

    final filtered = service.filterFilesBasedOnOnlyNew(files, null);

    expect(filtered, files);
  });
}
