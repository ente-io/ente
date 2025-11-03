import "package:flutter_test/flutter_test.dart";
import "package:photos/services/faces_timeline/faces_timeline_service.dart";

Map<String, dynamic> _buildFace(
  String faceId,
  int fileId,
  DateTime creationDate,
) {
  return {
    "faceId": faceId,
    "fileId": fileId,
    "creationTime": creationDate.microsecondsSinceEpoch,
    "year": creationDate.year,
  };
}

void main() {
  group("Faces timeline selection", () {
    test("returns ready when at least seven eligible years are present", () {
      final faces = <Map<String, dynamic>>[];
      for (int year = 2010; year < 2017; year++) {
        for (int index = 0; index < 5; index++) {
          faces.add(
            _buildFace(
              "face-$year-$index",
              year * 10 + index,
              DateTime(year, 1, 1).add(Duration(days: index * 60)),
            ),
          );
        }
      }

      final result = selectTimelineEntriesTask({
        "faces": faces,
        "minYears": 7,
        "minFaces": 4,
      });

      expect(result["status"], equals("ready"));
      final years = (result["years"] as List<dynamic>).cast<int>();
      expect(years, equals(List<int>.generate(7, (i) => 2010 + i)));

      final entries =
          (result["entries"] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(entries.length, equals(28));
      final faceIds = entries.map((entry) => entry["faceId"]).toSet();
      expect(faceIds.length, equals(entries.length));

      for (final year in years) {
        final yearEntries =
            entries.where((entry) => entry["year"] == year).toList();
        expect(yearEntries.length, equals(4));
      }
    });

    test("returns ineligible when fewer than seven years qualify", () {
      final faces = <Map<String, dynamic>>[];
      for (int year = 2011; year < 2017; year++) {
        for (int index = 0; index < 4; index++) {
          faces.add(
            _buildFace(
              "face-$year-$index",
              year * 100 + index,
              DateTime(year, 3, 1).add(Duration(days: index * 40)),
            ),
          );
        }
      }

      final result = selectTimelineEntriesTask({
        "faces": faces,
        "minYears": 7,
        "minFaces": 4,
      });

      expect(result["status"], equals("ineligible"));
      expect(result["eligibleYearCount"], equals(6));
      expect(result["entries"], isNull);
    });
  });
}
