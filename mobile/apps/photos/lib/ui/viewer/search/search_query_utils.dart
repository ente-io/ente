import "package:ente_pure_utils/ente_pure_utils.dart";

bool isYearSearchQuery(String query) {
  final yearAsInt = int.tryParse(query);
  return yearAsInt != null && yearAsInt <= currentYear;
}
