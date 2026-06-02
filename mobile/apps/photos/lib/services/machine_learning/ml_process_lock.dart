import "dart:async";

import "package:logging/logging.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/main.dart"
    show
        isProcessBg,
        kFGTaskDeathTimeoutInMicroseconds,
        kLastBGTaskHeartBeatTime,
        kLastFGTaskHeartBeatTime;
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite/sqflite.dart";

/// Cross-process (foreground vs background WorkManager isolate) mutual exclusion
/// for the ML pipeline ([MLService.runAllML]).
///
/// The foreground UI engine and the background WorkManager engine run in the
/// same OS process but in separate Dart isolates, each with its own
/// [MLService] singleton and its own SQLite connections to the ML databases.
/// Without coordination, both can index at the same time and collide on
/// `BEGIN IMMEDIATE`, producing "database is locked" errors and duplicated
/// work.
///
/// This lock lives in its own tiny SQLite database (so it never contends with
/// the ML databases it protects) and reuses the existing heartbeat signals
/// written by the foreground and background processes to decide whether the
/// other side is alive. The foreground always has priority: a background run
/// yields as soon as the foreground becomes active (see the heartbeat checks in
/// [MLService]), and the foreground will steal the lock from a dead/frozen
/// background holder.
class MLProcessLock {
  static const _databaseName = "ente.ml_process_lock.db";
  static const _table = "ml_process_lock";
  static const _columnID = "id";
  static const _columnOwner = "owner";
  static const _columnTime = "time";

  /// The single lock id guarding [MLService.runAllML].
  static const _lockId = "ml_run";

  static const _ownerBackground = "background";
  static const _ownerForeground = "foreground";

  /// Locks older than this are considered abandoned and swept, even if a
  /// heartbeat check would otherwise keep them alive. Acts as a final safety
  /// net so a run can never be blocked forever.
  static final _kLockSafetyExpiry = const Duration(hours: 4).inMicroseconds;

  /// How long the foreground waits for a live background run to yield before
  /// force-stealing the lock.
  static final _kForegroundAcquireTimeout = const Duration(
    seconds: 20,
  ).inMicroseconds;

  static const _kAcquirePollInterval = Duration(seconds: 1);

  final _logger = Logger("MLProcessLock");

  MLProcessLock._privateConstructor();
  static final MLProcessLock instance = MLProcessLock._privateConstructor();

  static Future<Database>? _dbFuture;
  Future<Database> get _database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            $_columnID TEXT PRIMARY KEY NOT NULL,
            $_columnOwner TEXT NOT NULL,
            $_columnTime INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  String get _myOwner => isProcessBg ? _ownerBackground : _ownerForeground;

  int get _now => DateTime.now().microsecondsSinceEpoch;

  /// Tries to acquire the cross-process ML run lock for the current process.
  ///
  /// Returns true if the lock was acquired and the caller may run ML. The
  /// caller MUST call [release] once done (typically in a `finally`).
  ///
  /// Policy:
  /// - The foreground has priority. If a live background run holds the lock it
  ///   will yield shortly (it polls the foreground heartbeat), so the
  ///   foreground retries briefly and then force-steals as a last resort.
  /// - The background defers to the foreground: if a live foreground run holds
  ///   the lock the background skips ML entirely.
  /// - Either side steals the lock from a dead/frozen holder.
  Future<bool> acquireForRun() async {
    final me = _myOwner;
    try {
      // Drop any lock left behind by a previous crashed run of our own type,
      // and sweep abandoned locks as a final safety net.
      await _releaseOwner(me);
      await _releaseAcquiredBefore(_now - _kLockSafetyExpiry);

      if (!isProcessBg) {
        return await _acquireForForeground(me);
      } else {
        return await _acquireForBackground(me);
      }
    } catch (e, s) {
      _logger.severe("Failed to acquire ML lock", e, s);
      return false;
    }
  }

  Future<bool> _acquireForForeground(String me) async {
    final deadline = _now + _kForegroundAcquireTimeout;
    while (true) {
      final holder = await _currentHolder();
      if (holder == null) {
        if (await _tryInsert(me)) return true;
      } else if (holder.owner == me) {
        return true;
      } else if (!await isBackgroundActive()) {
        _logger.info("Background ML holder is dead, stealing ML lock");
        await _releaseOwner(holder.owner);
        if (await _tryInsert(me)) return true;
      }
      if (_now >= deadline) {
        _logger.warning(
          "Foreground waited too long for the ML lock, force-stealing from background",
        );
        await _releaseOwner(_ownerBackground);
        return await _tryInsert(me);
      }
      await Future.delayed(_kAcquirePollInterval);
    }
  }

  Future<bool> _acquireForBackground(String me) async {
    final holder = await _currentHolder();
    if (holder != null && holder.owner != me) {
      if (await isForegroundActive()) {
        _logger.info(
          "Foreground is active and holds the ML lock, skipping background ML",
        );
        return false;
      }
      _logger.info("Foreground ML holder is dead, stealing ML lock");
      await _releaseOwner(holder.owner);
    }
    return await _tryInsert(me);
  }

  /// Releases the lock if it is held by the current process.
  Future<void> release() async {
    try {
      await _releaseOwner(_myOwner);
    } catch (e, s) {
      _logger.severe("Failed to release ML lock", e, s);
    }
  }

  /// Whether the foreground process has emitted a heartbeat recently.
  Future<bool> isForegroundActive() =>
      _isHeartBeatFresh(kLastFGTaskHeartBeatTime);

  /// Whether the background process has emitted a heartbeat recently.
  Future<bool> isBackgroundActive() =>
      _isHeartBeatFresh(kLastBGTaskHeartBeatTime);

  Future<bool> _isHeartBeatFresh(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final lastHeartBeat = prefs.getInt(key) ?? 0;
    return lastHeartBeat > (_now - kFGTaskDeathTimeoutInMicroseconds);
  }

  Future<({String owner, int time})?> _currentHolder() async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: '$_columnID = ?',
      whereArgs: [_lockId],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return (owner: row[_columnOwner] as String, time: row[_columnTime] as int);
  }

  Future<bool> _tryInsert(String owner) async {
    final db = await _database;
    try {
      await db.insert(_table, {
        _columnID: _lockId,
        _columnOwner: owner,
        _columnTime: _now,
      }, conflictAlgorithm: ConflictAlgorithm.fail);
      return true;
    } catch (_) {
      // Another process inserted the row first.
      return false;
    }
  }

  Future<void> _releaseOwner(String owner) async {
    final db = await _database;
    await db.delete(
      _table,
      where: '$_columnID = ? AND $_columnOwner = ?',
      whereArgs: [_lockId, owner],
    );
  }

  Future<void> _releaseAcquiredBefore(int time) async {
    final db = await _database;
    await db.delete(_table, where: '$_columnTime < ?', whereArgs: [time]);
  }
}
