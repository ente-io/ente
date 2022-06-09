import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/network.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/home_widget.dart';

final lightThemeData = ThemeData(
  fontFamily: 'Inter',
  brightness: Brightness.light,
  hintColor: Colors.grey,
  primaryColor: Colors.deepOrangeAccent,
  primaryColorLight: Colors.black54,
  iconTheme: IconThemeData(color: Colors.black),
  primaryIconTheme: IconThemeData(color: Colors.red, opacity: 1.0, size: 50.0),
  colorScheme: ColorScheme.light(
      primary: Colors.black, secondary: Color.fromARGB(255, 163, 163, 163)),
  accentColor: Color.fromRGBO(0, 0, 0, 0.6),
  buttonColor: Color.fromRGBO(45, 194, 98, 1.0),
  outlinedButtonTheme: buildOutlinedButtonThemeData(
    bgDisabled: Colors.grey.shade500,
    bgEnabled: Colors.black,
    fgDisabled: Colors.white,
    fgEnabled: Colors.white,
  ),
  elevatedButtonTheme: buildElevatedButtonThemeData(
      onPrimary: Colors.white, primary: Colors.black),
  toggleableActiveColor: Colors.green[400],
  scaffoldBackgroundColor: Colors.white,
  backgroundColor: Colors.white,
  appBarTheme: AppBarTheme().copyWith(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    iconTheme: IconThemeData(color: Colors.black),
    elevation: 0,
  ),
  //https://api.flutter.dev/flutter/material/TextTheme-class.html
  textTheme: _buildTextTheme(Colors.black),
  primaryTextTheme: TextTheme().copyWith(
      bodyText2: TextStyle(color: Colors.yellow),
      bodyText1: TextStyle(color: Colors.orange)),
  cardColor: Color.fromRGBO(250, 250, 250, 1.0),
  dialogTheme: DialogTheme().copyWith(
      backgroundColor: Color.fromRGBO(250, 250, 250, 1.0), //
      titleTextStyle: TextStyle(
          color: Colors.black, fontSize: 32, fontWeight: FontWeight.w600),
      contentTextStyle: TextStyle(
          fontFamily: 'Inter-Medium',
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
  inputDecorationTheme: InputDecorationTheme().copyWith(
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: Color.fromRGBO(45, 194, 98, 1.0),
      ),
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    side: BorderSide(
      color: Colors.black,
      width: 2,
    ),
    fillColor: MaterialStateProperty.resolveWith((states) {
      return states.contains(MaterialState.selected)
          ? Colors.black
          : Colors.white;
    }),
    checkColor: MaterialStateProperty.resolveWith((states) {
      return states.contains(MaterialState.selected)
          ? Colors.white
          : Colors.black;
    }),
  ),
);

final darkThemeData = ThemeData(
  fontFamily: 'Inter',
  brightness: Brightness.dark,
  primaryColorLight: Colors.white70,
  iconTheme: IconThemeData(color: Colors.white),
  primaryIconTheme: IconThemeData(color: Colors.red, opacity: 1.0, size: 50.0),
  hintColor: Colors.grey,
  colorScheme: ColorScheme.dark(primary: Colors.white),
  accentColor: Color.fromRGBO(45, 194, 98, 0.2),
  buttonColor: Color.fromRGBO(45, 194, 98, 1.0),
  buttonTheme: ButtonThemeData().copyWith(
    buttonColor: Color.fromRGBO(45, 194, 98, 1.0),
  ),
  textTheme: _buildTextTheme(Colors.white),
  toggleableActiveColor: Colors.green[400],
  outlinedButtonTheme: buildOutlinedButtonThemeData(
      bgDisabled: Colors.grey.shade500,
      bgEnabled: Colors.white,
      fgDisabled: Colors.white,
      fgEnabled: Colors.black),
  elevatedButtonTheme: buildElevatedButtonThemeData(
      onPrimary: Colors.black, primary: Colors.white),
  scaffoldBackgroundColor: Colors.black,
  backgroundColor: Colors.black,
  appBarTheme: AppBarTheme().copyWith(
    color: Color.fromRGBO(10, 20, 20, 1.0),
    elevation: 0,
  ),
  cardColor: Color.fromRGBO(10, 15, 15, 1.0),
  dialogTheme: DialogTheme().copyWith(
      backgroundColor: Color.fromRGBO(10, 15, 15, 1.0),
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600),
      contentTextStyle: TextStyle(
          fontFamily: 'Inter-Medium',
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
  inputDecorationTheme: InputDecorationTheme().copyWith(
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: Color.fromRGBO(45, 194, 98, 1.0),
      ),
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    side: BorderSide(
      color: Colors.grey,
      width: 2,
    ),
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.grey;
      } else {
        return Colors.black;
      }
    }),
    checkColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.black;
      } else {
        return Colors.grey;
      }
    }),
  ),
);

TextTheme _buildTextTheme(Color textColor) {
  return TextTheme().copyWith(
      headline4: TextStyle(
        color: textColor,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      headline5: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      headline6: TextStyle(
          color: textColor,
          fontSize: 18,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600),
      subtitle1: TextStyle(
          color: textColor,
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500),
      subtitle2: TextStyle(
          color: textColor,
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500),
      bodyText1: TextStyle(
          fontFamily: 'Inter',
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400),
      caption: TextStyle(
        color: textColor.withOpacity(0.6),
        fontSize: 14,
      ),
      overline: TextStyle(
        color: textColor.withOpacity(0.8),
        fontSize: 12,
      ));
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
    _logger.info('init App');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configureBackgroundFetch();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return AdaptiveTheme(
        light: lightThemeData,
        dark: darkThemeData,
        initial: AdaptiveThemeMode.system,
        builder: (lightTheme, dartTheme) => MaterialApp(
          title: "ente",
          themeMode: ThemeMode.system,
          theme: lightTheme,
          darkTheme: dartTheme,
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
        ),
      );
    } else {
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final String stateChangeReason = 'app -> $state';
    if (state == AppLifecycleState.resumed) {
      AppLifecycleService.instance
          .onAppInForeground(stateChangeReason + ': sync now');
      SyncService.instance.sync();
    } else {
      AppLifecycleService.instance.onAppInBackground(stateChangeReason);
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
      _logger.info("BG task timeout taskID: $taskId");
      widget.killBackgroundTask(taskId);
    }).then((int status) {
      _logger.info('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      _logger.info('[BackgroundFetch] configure ERROR: $e');
    });
  }
}
