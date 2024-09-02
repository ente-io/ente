import "dart:collection" show Queue;
import "dart:convert" show jsonEncode, jsonDecode;

import "package:logging/logging.dart";
import "package:photos/core/error-reporting/super_logging.dart";

class IsolateLogString {
  final String logString;
  final Object? error;

  IsolateLogString(this.logString, this.error);

  String toJsonString() => jsonEncode({
        'logString': logString,
        'error': error,
      });

  static IsolateLogString fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return IsolateLogString(
      json['logString'] as String,
      json['error'],
    );
  }
}

class IsolateLogger {
  final Queue<IsolateLogString> fileQueueEntries = Queue();

  Future onLogRecordInIsolate(LogRecord rec) async {
    final str = rec.toPrettyString(null, true);

    // write to stdout
    SuperLogging.printLog(str);

    // push to log queue
    fileQueueEntries.add(IsolateLogString(str, rec.error != null));
  }

  /// WARNING: only call this from the isolate
  Queue<String> getLogStringsAndClear() {
    if (fileQueueEntries.isEmpty) return Queue<String>();
    final result = Queue<String>();
    while (fileQueueEntries.isNotEmpty) {
      final entry = fileQueueEntries.removeFirst();
      result.add(entry.toJsonString());
    }
    return result;
  }

  /// WARNING: only call this from the main thread
  static void handLogStringsToMainLogger(List<String> logs) {
    while (logs.isNotEmpty) {
      final logString = logs.removeAt(0);
      final log = IsolateLogString.fromJsonString(logString);
      SuperLogging.saveLogString(log.logString, log.error);
    }
  }
}
