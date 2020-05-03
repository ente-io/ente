library super_logging;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_ip/get_ip.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:package_info/package_info.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry/sentry.dart';

export 'package:sentry/sentry.dart' show User;

typedef Future<User> GetUser();
typedef FutureOr<void> FutureOrVoidCallback();

extension SuperLogRecord on LogRecord {
  String toPrettyString([String extraLines]) {
    var header = "[$loggerName] [$level] [$time]";

    var msg = "$header $message";

    if (error != null) {
      msg += "\n$error";
    }
    if (stackTrace != null) {
      msg += "\n$stackTrace";
    }

    for (var line in extraLines?.split('\n') ?? []) {
      msg += '\n$header $line';
    }

    msg += '\n';

    return msg;
  }

  Event toEvent({String appVersion, User user}) {
    return Event(
      release: appVersion,
      level: SeverityLevel.error,
      culprit: message,
      loggerName: loggerName,
      exception: error,
      stackTrace: stackTrace,
      userContext: user,
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
  /// If this is an empty string (['']),
  /// then a 'logs' directory will be created in [getTemporaryDirectory()] (default).
  ///
  /// If this is [null], file logging is completely disabled.
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

  LogConfig({
    this.sentryDsn,
    this.sentryRetryDelay = const Duration(seconds: 30),
    this.logDirPath = '',
    this.maxLogFiles = 10,
    this.enableInDebugMode = false,
    this.body,
    this.dateFmt,
  }) {
    dateFmt ??= DateFormat("y-M-d");
  }
}

class SuperLogging {
  /// The logger for SuperLogging
  static final $ = Logger('super_logging');

  /// The current super logging configuration
  static LogConfig config;

  static Future<void> main([LogConfig config]) async {
    config ??= LogConfig();
    SuperLogging.config = config;

    WidgetsFlutterBinding.ensureInitialized();
    deviceInfo = await getDeviceInfo();
    ipAddress = await getIpAddress();
    appVersion = await getAppVersion();
    updateUser();

    final enable = config.enableInDebugMode || kReleaseMode;
    sentryIsEnabled = enable && config.sentryDsn != null;
    fileIsEnabled = enable && config.logDirPath != null;

    if (fileIsEnabled) {
      await setupLogDir();
    }
    if (sentryIsEnabled) {
      sentryUploader();
    }

    mainloop();
    $.info("mainloop started 💥");

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
      };
      await runZoned(config.body, onError: (e, trace) {
        $.fine("uncaught error from runZoned()", e, trace);
      });
    } else {
      await config.body();
    }
  }

  static var _lastExtraLines = '';

  static Future<void> mainloop() async {
    Logger.root.level = Level.ALL;

    await for (final rec in Logger.root.onRecord) {
      // log misc info if it changed
      var extraLines =
          "app version: '$appVersion'\ncurrent user: ${user.toJson()}";
      if (extraLines != _lastExtraLines) {
        _lastExtraLines = extraLines;
      } else {
        extraLines = null;
      }

      var str = rec.toPrettyString(extraLines);

      // write to stdout
      print(str);

      // write to logfile
      if (fileIsEnabled) {
        await logFile.writeAsString(str, mode: FileMode.append, flush: true);
      }

      // add error to sentry queue
      if (sentryIsEnabled && rec.error != null) {
        sentryQueueControl.add(
          rec.toEvent(appVersion: appVersion, user: user),
        );
      }
    }
  }

  /// A queue to be consumed by [sentryUploader].
  static var sentryQueueControl = StreamController<Event>();

  /// Whether sentry logging is currently enabled or not.
  static bool sentryIsEnabled;

  static Future<void> sentryUploader() async {
    var client = SentryClient(dsn: config.sentryDsn);

    await for (final event in sentryQueueControl.stream) {
      dynamic error, trace;

      try {
        var response = await client.capture(event: event);
        error = response.error;
      } catch (e, t) {
        error = e;
        trace = t;
      }

      if (error == null) continue;
      $.fine(
        "sentry upload failed; will retry after ${config.sentryRetryDelay}",
        error,
        trace,
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
      var tmpDir = await getTemporaryDirectory();
      dirPath = '${tmpDir.path}/logs';
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

    logFile = File("$dirPath/${config.dateFmt.format(DateTime.now())}");
  }

  /// The current user.
  ///
  /// It's generally recommended to use [updateUser], than directly modify this.
  static User user;

  /// Current device information as a JSON string,
  /// obtained from device_info plugin.
  ///
  /// See: [getDeviceInfo]
  static String deviceInfo;

  /// Current ip address, obtained from get_ip plugin.
  ///
  /// See: [getIpAddress]
  static String ipAddress;

  /// Current app version, obtained from package_info plugin.
  ///
  /// See: [getAppVersion]
  static String appVersion;

  /// set the properties for current user.
  static void updateUser({
    String id,
    String username,
    String email,
    Map<String, String> extraInfo,
  }) {
    extraInfo ??= {};
    extraInfo.putIfAbsent('deviceInfo', () => deviceInfo);

    user = User(
      id: id ?? '',
      username: username,
      email: email,
      ipAddress: ipAddress,
      extras: extraInfo,
    );
  }

  static Future<String> getDeviceInfo() async {
    String method = '';
    if (Platform.isAndroid) {
      method = 'getAndroidDeviceInfo';
    } else if (Platform.isIOS) {
      method = 'getIosDeviceInfo';
    }

    if (method.isEmpty) {
      return '';
    }

    var result = await DeviceInfoPlugin.channel.invokeMethod(method);
    var data = jsonEncode(result);

    return data;
  }

  static Future<String> getAppVersion() async {
    var pkgInfo = await PackageInfo.fromPlatform();
    return pkgInfo.version;
  }

  static Future<String> getIpAddress() async {
    return await GetIp.ipAddress;
  }
}
