library super_logging;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry/sentry.dart';

export 'package:sentry/sentry.dart' show User;

typedef FutureOr<void> FutureOrVoidCallback();

extension SuperString on String {
  Iterable<String> chunked(int chunkSize) sync* {
    var start = 0;

    while (true) {
      var stop = start + chunkSize;
      if (stop > length) break;
      yield substring(start, stop);
      start = stop;
    }

    if (start < length) {
      yield substring(start);
    }
  }
}

extension SuperLogRecord on LogRecord {
  String toPrettyString([String extraLines]) {
    var header = "[$loggerName] [$level] [$time]";

    var msg = "$header $message";

    if (error != null) {
      msg += "\n⤷ type: ${error.runtimeType}\n⤷ error: $error";
    }
    if (stackTrace != null) {
      msg += "\n⤷ trace: $stackTrace";
    }

    for (var line in extraLines?.split('\n') ?? []) {
      msg += '\n$header $line';
    }

    return msg;
  }

  Event toEvent({String appVersion}) {
    return Event(
      release: appVersion,
      level: SeverityLevel.error,
      culprit: message,
      loggerName: loggerName,
      exception: error,
      stackTrace: stackTrace,
    );
  }
}

class LogConfig {
  /// The DSN for a Sentry app.
  /// This can be obtained from the Sentry apps's "settings > Client Keys (DSN)" page.
  ///
  /// Only logs containing errors are sent to sentry.
  /// Errors can be caught using a try-catch block, like so:
  ///
  /// ```
  /// final logger = Logger("main");
  ///
  /// try {
  ///   // do something dangerous here
  /// } catch(e, trace) {
  ///   logger.info("Huston, we have a problem", e, trace);
  /// }
  /// ```
  ///
  /// If this is [null], Sentry logger is completely disabled (default).
  String sentryDsn;

  /// A built-in retry mechanism for sending errors to sentry.
  ///
  /// This parameter defines the time to wait for, before retrying.
  Duration sentryRetryDelay;

  /// Path of the directory where log files will be stored.
  ///
  /// If this is [null], file logging is completely disabled (default).
  ///
  /// If this is an empty string (['']),
  /// then a 'logs' directory will be created in [getTemporaryDirectory()].
  ///
  /// A non-empty string will be treated as an explicit path to a directory.
  ///
  /// The chosen directory can be accessed using [SuperLogging.logFile.parent].
  String logDirPath;

  /// The maximum number of log files inside [logDirPath].
  ///
  /// One log file is created per day.
  /// Older log files are deleted automatically.
  int maxLogFiles;

  /// Whether to enable super logging features in debug mode.
  ///
  /// Sentry and file logging are typically not needed in debug mode,
  /// where a complete logcat is available.
  bool enableInDebugMode;

  /// If provided, super logging will invoke this function, and
  /// any uncaught errors during its execution will be reported.
  ///
  /// Works by using [FlutterError.onError] and [runZoned].
  FutureOrVoidCallback body;

  /// The date format for storing log files.
  ///
  /// `DateFormat('y-M-d')` by default.
  DateFormat dateFmt;

  String prefix;

  LogConfig({
    this.sentryDsn,
    this.sentryRetryDelay = const Duration(seconds: 30),
    this.logDirPath,
    this.maxLogFiles = 10,
    this.enableInDebugMode = false,
    this.body,
    this.dateFmt,
    this.prefix = "",
  }) {
    dateFmt ??= DateFormat("y-M-d");
  }
}

class SuperLogging {
  /// The logger for SuperLogging
  static final $ = Logger('ente_logging');

  /// The current super logging configuration
  static LogConfig config;

  static SentryClient sentryClient;

  static Future<void> main([LogConfig config]) async {
    config ??= LogConfig();
    SuperLogging.config = config;

    WidgetsFlutterBinding.ensureInitialized();

    appVersion ??= await getAppVersion();

    final enable = config.enableInDebugMode || kReleaseMode;
    sentryIsEnabled = enable && config.sentryDsn != null;
    fileIsEnabled = enable && config.logDirPath != null;

    if (fileIsEnabled) {
      await setupLogDir();
    }
    if (sentryIsEnabled && sentryClient == null) {
      setupSentry();
    }

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(onLogRecord);

    if (!enable) {
      $.info("detected debug mode; sentry & file logging disabled.");
    }
    if (fileIsEnabled) {
      $.info("using this log file for today: $logFile");
    }
    if (sentryIsEnabled) {
      $.info("sentry uploader started");
    }

    if (config.body == null) return;

    if (enable) {
      FlutterError.onError = (details) {
        $.fine(
          "uncaught error from FlutterError.onError()",
          details.exception,
          details.stack,
        );
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        _sendErrorToSentry(details.exception, details.stack);
      };
      await runZonedGuarded(config.body, (e, trace) {
        $.fine("uncaught error from runZoned()", e, trace);
      });
    } else {
      await config.body();
    }
  }

  static void _sendErrorToSentry(Object error, StackTrace stack) {
    try {
      sentryClient.captureException(
        exception: error,
        stackTrace: stack,
      );
      $.info('Error sent to sentry.io: $error');
    } catch (e) {
      $.info('Sending report to sentry.io failed: $e');
      $.info('Original error: $error');
    }
  }

  static var _lastExtraLines = '';

  static Future onLogRecord(LogRecord rec) async {
    // log misc info if it changed
    var extraLines = "app version: '$appVersion'\n";
    if (extraLines != _lastExtraLines) {
      _lastExtraLines = extraLines;
    } else {
      extraLines = null;
    }

    var str = config.prefix + " " + rec.toPrettyString(extraLines);

    // write to stdout
    printLog(str);

    // write to logfile
    if (fileIsEnabled) {
      final strForLogFile = str + '\n';
      await logFile.writeAsString(strForLogFile,
          mode: FileMode.append, flush: true);
    }

    // add error to sentry queue
    if (sentryIsEnabled && rec.error != null) {
      var event = rec.toEvent(appVersion: appVersion);
      sentryQueueControl.add(event);
    }
  }

  // Logs on must be chunked or they get truncated otherwise
  // See https://github.com/flutter/flutter/issues/22665
  static var logChunkSize = 800;

  static void printLog(String text) {
    text.chunked(logChunkSize).forEach(print);
  }

  /// A queue to be consumed by [setupSentry].
  static final sentryQueueControl = StreamController<Event>();

  /// Whether sentry logging is currently enabled or not.
  static bool sentryIsEnabled;

  static Future<void> setupSentry() async {
    sentryClient = SentryClient(dsn: config.sentryDsn);
    await for (final event in sentryQueueControl.stream) {
      dynamic error;
      try {
        var response = await sentryClient.capture(event: event);
        error = response.error;
      } catch (e) {
        error = e;
      }

      if (error == null) continue;
      $.fine(
        "sentry upload failed; will retry after ${config.sentryRetryDelay} ($error)",
      );
      doSentryRetry(event);
    }
  }

  static void doSentryRetry(Event event) async {
    await Future.delayed(config.sentryRetryDelay);
    sentryQueueControl.add(event);
  }

  /// The log file currently in use.
  static File logFile;

  /// Whether file logging is currently enabled or not.
  static bool fileIsEnabled;

  static Future<void> setupLogDir() async {
    var dirPath = config.logDirPath;

    // choose [logDir]
    if (dirPath.isEmpty) {
      var root = await getExternalStorageDirectory();
      dirPath = '${root.path}/logs';
    }

    // create [logDir]
    var dir = Directory(dirPath);
    await dir.create(recursive: true);

    var files = <File>[];
    var dates = <File, DateTime>{};

    // collect all log files with valid names
    await for (final file in dir.list()) {
      try {
        var date = config.dateFmt.parse(basename(file.path));
        dates[file] = date;
      } on FormatException {}
    }

    // delete old log files, if [maxLogFiles] is exceeded.
    if (files.length > config.maxLogFiles) {
      // sort files based on ascending order of date (older first)
      files.sort((a, b) => dates[a].compareTo(dates[b]));

      var extra = files.length - config.maxLogFiles;
      var toDelete = files.sublist(0, extra);

      for (var file in toDelete) {
        await file.delete();
      }
    }

    logFile = File("$dirPath/${config.dateFmt.format(DateTime.now())}.txt");
  }

  /// Current app version, obtained from package_info plugin.
  ///
  /// See: [getAppVersion]
  static String appVersion;

  static Future<String> getAppVersion() async {
    var pkgInfo = await PackageInfo.fromPlatform();
    return "${pkgInfo.version}+${pkgInfo.buildNumber}";
  }
}
