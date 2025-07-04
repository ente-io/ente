import "package:flutter/foundation.dart";
import "package:sqlite_async/sqlite_async.dart";

mixin SqlDbBase {
  static const _params = {};

  static String getParams(int count) {
    if (!_params.containsKey(count)) {
      final params = List.generate(count, (_) => "?").join(", ");
      _params[count] = params;
    }
    return _params[count]!;
  }

  Future<void> migrate(
    SqliteDatabase database,
    List<String> migrationScripts,
  ) async {
    final result = await database.execute('PRAGMA user_version');
    final currentVersion = result[0]['user_version'] as int;
    final toVersion = migrationScripts.length;

    if (currentVersion < toVersion) {
      debugPrint(
        "$runtimeType migrating database from $currentVersion to $toVersion",
      );
      await database.writeTransaction((tx) async {
        for (int i = currentVersion + 1; i <= toVersion; i++) {
          try {
            await tx.execute(migrationScripts[i - 1]);
          } catch (e) {
            debugPrint(
              "$runtimeType Error running migration script index ${i - 1} $e",
            );
            rethrow;
          }
        }
        await tx.execute('PRAGMA user_version = $toVersion');
      });
    } else if (currentVersion > toVersion) {
      throw AssertionError(
        "currentVersion($currentVersion) cannot be greater than toVersion($toVersion)",
      );
    }
  }
}
