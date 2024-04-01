import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DirectoryUtils {
  static Future<String> getDatabasePath(String databaseName) async => p.joinAll(
        [
          (await getApplicationDocumentsDirectory()).path,
          "ente",
          ".$databaseName",
        ],
      );
}
