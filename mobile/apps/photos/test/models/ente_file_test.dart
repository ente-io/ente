import 'package:flutter_test/flutter_test.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';

void main() {
  group('EnteFile.copyForRemoteDownload', () {
    test('returns a clone with localID cleared', () {
      final file = EnteFile()
        ..uploadedFileID = 123
        ..localID = "asset-id"
        ..title = "IMG_0001.jpg"
        ..fileType = FileType.image;

      final cloned = file.copyForRemoteDownload();

      expect(cloned, isNot(same(file)));
      expect(cloned.localID, isNull);
      expect(cloned.uploadedFileID, file.uploadedFileID);
      expect(cloned.title, file.title);
      expect(cloned.isRemoteFile, isTrue);
      expect(file.localID, "asset-id");
    });
  });
}
