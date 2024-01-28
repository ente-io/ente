import 'package:path_provider/path_provider.dart';

class DirectoryUtils {
  static Future<String> getDatabasePath(String databaseName) async =>
      (await getDownloadsDirectory())!
          .path
          .replaceFirst('Downloads', '.$databaseName');
}
