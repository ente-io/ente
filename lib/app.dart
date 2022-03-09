import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/network.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/home_widget.dart';

final lightThemeData = ThemeData(
  fontFamily: 'Inter',
  brightness: Brightness.light,
  hintColor: Colors.grey,
  iconTheme: IconThemeData(color: Colors.black),
  primaryIconTheme: IconThemeData(color: Colors.red, opacity: 1.0, size: 50.0),
  colorScheme: ColorScheme.light(primary: Colors.black),
  accentColor: Color.fromRGBO(45, 194, 98, 0.2),
  buttonColor: Color.fromRGBO(45, 194, 98, 1.0),
  buttonTheme: ButtonThemeData().copyWith(
    buttonColor: Color.fromRGBO(45, 194, 98, 1.0),
  ),
  toggleableActiveColor: Colors.red[400],
  scaffoldBackgroundColor: Colors.white,
  bottomAppBarColor: Color.fromRGBO(196, 196, 196, 1.0),
  backgroundColor: Colors.white,
  appBarTheme: AppBarTheme().copyWith(color: Colors.blue),
  //https://api.flutter.dev/flutter/material/TextTheme-class.html
  textTheme: TextTheme().copyWith(
      headline6: TextStyle(
          color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
      subtitle1: TextStyle(
          color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
      caption: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 14),
      overline: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 12)),

  primaryTextTheme: TextTheme().copyWith(
      bodyText2: TextStyle(color: Colors.yellow),
      bodyText1: TextStyle(color: Colors.orange)),
  cardColor: Color.fromRGBO(250, 250, 250, 1.0),
  //
  dialogTheme: DialogTheme().copyWith(
    backgroundColor: Color.fromRGBO(250, 250, 250, 1.0), //
  ),
  textSelectionTheme: TextSelectionThemeData().copyWith(
    cursorColor: Colors.white.withOpacity(0.5),
  ),
  inputDecorationTheme: InputDecorationTheme().copyWith(
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: Color.fromRGBO(45, 194, 98, 1.0),
      ),
    ),
  ),
);

final darkThemeData = ThemeData(
  fontFamily: 'Inter',
  brightness: Brightness.dark,
  iconTheme: IconThemeData(color: Colors.white),
  primaryIconTheme: IconThemeData(color: Colors.red, opacity: 1.0, size: 50.0),
  hintColor: Colors.grey,
  bottomAppBarColor: Color.fromRGBO(196, 196, 196, 1.0),

  colorScheme: ColorScheme.dark(),
  accentColor: Color.fromRGBO(45, 194, 98, 0.2),
  buttonColor: Color.fromRGBO(45, 194, 98, 1.0),
  buttonTheme: ButtonThemeData().copyWith(
    buttonColor: Color.fromRGBO(45, 194, 98, 1.0),
  ),
  // primaryColor: Colors.red,
  textTheme: TextTheme().copyWith(
      headline6: TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      subtitle1: TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      caption: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 14,
      ),
      overline: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 12,
      )),
  toggleableActiveColor: Colors.green[400],
  scaffoldBackgroundColor: Colors.black,
  backgroundColor: Colors.black,
  appBarTheme: AppBarTheme().copyWith(
    color: Color.fromRGBO(10, 20, 20, 1.0),
  ),
  cardColor: Color.fromRGBO(10, 15, 15, 1.0),
  dialogTheme: DialogTheme().copyWith(
    backgroundColor: Color.fromRGBO(10, 15, 15, 1.0),
  ),
  textSelectionTheme: TextSelectionThemeData().copyWith(
    cursorColor: Colors.white.withOpacity(0.5),
  ),
  inputDecorationTheme: InputDecorationTheme().copyWith(
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: Color.fromRGBO(45, 194, 98, 1.0),
      ),
    ),
  ),
);

extension CustomColorScheme on ColorScheme {
  Color get defaultTextColor =>
      brightness == Brightness.light ? Colors.black : Colors.white;
}

class EnteApp extends StatefulWidget {
  static const _homeWidget = HomeWidget();

  final Future<void> Function(String) runBackgroundTask;
  final Future<void> Function(String) killBackgroundTask;

  EnteApp(
    this.runBackgroundTask,
    this.killBackgroundTask, {
    Key key,
  }) : super(key: key);

  @override
  _EnteAppState createState() => _EnteAppState();
}

class _EnteAppState extends State<EnteApp> with WidgetsBindingObserver {
  final _logger = Logger("EnteAppState");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configureBackgroundFetch();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ente",
      themeMode: ThemeMode.system,
      theme: lightThemeData,
      darkTheme: darkThemeData,
      home: EnteApp._homeWidget,
      debugShowCheckedModeBanner: false,
      navigatorKey: Network.instance.getAlice().getNavigatorKey(),
      builder: EasyLoading.init(),
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLifecycleService.instance.onAppInForeground();
      SyncService.instance.sync();
    } else {
      AppLifecycleService.instance.onAppInBackground();
    }
  }

  void _configureBackgroundFetch() {
    BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          forceAlarmManager: false,
          stopOnTerminate: false,
          startOnBoot: true,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.NONE,
        ), (String taskId) async {
      await widget.runBackgroundTask(taskId);
    }, (taskId) {
      _logger.info("BG task timeout");
      widget.killBackgroundTask(taskId);
    }).then((int status) {
      _logger.info('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      _logger.info('[BackgroundFetch] configure ERROR: $e');
    });
  }
}
