import "package:flutter_test/flutter_test.dart";
import "package:locker/models/file_type.dart";
import "package:locker/models/info/info_item.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/services/files/sync/models/file_magic.dart";
import "package:locker/services/info_file_service.dart";

void main() {
  group("InfoFileService.extractInfoFromFile", () {
    test("parses hyphenated account credential types", () {
      final file = EnteFile()
        ..fileType = FileType.info
        ..title = "GitHub"
        ..pubMagicMetadata = PubMagicMetadata(
          info: {
            "type": "account-credential",
            "data": {
              "name": "GitHub",
              "username": "octocat",
              "password": "secret",
            },
          },
          noThumb: true,
        );

      final item = InfoFileService.instance.extractInfoFromFile(file);

      expect(item, isNotNull);
      expect(item!.type, InfoType.accountCredential);

      final data = item.data as AccountCredentialData;
      expect(data.name, "GitHub");
      expect(data.username, "octocat");
      expect(data.password, "secret");
    });

    test("parses hyphenated physical record types", () {
      final file = EnteFile()
        ..fileType = FileType.info
        ..title = "Passport"
        ..pubMagicMetadata = PubMagicMetadata(
          info: {
            "type": "physical-record",
            "data": {
              "name": "Passport",
              "location": "Home safe",
              "notes": "Top shelf",
            },
          },
          noThumb: true,
        );

      final item = InfoFileService.instance.extractInfoFromFile(file);

      expect(item, isNotNull);
      expect(item!.type, InfoType.physicalRecord);

      final data = item.data as PhysicalRecordData;
      expect(data.name, "Passport");
      expect(data.location, "Home safe");
      expect(data.notes, "Top shelf");
    });
  });
}
