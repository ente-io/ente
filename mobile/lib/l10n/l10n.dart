import "package:flutter/widgets.dart";
import "package:photos/generated/l10n.dart";
import "package:shared_preferences/shared_preferences.dart";

extension AppLocalizationsX on BuildContext {
  S get l10n => S.of(this);
}

// list of locales which are enabled for auth app.
// Add more language to the list only when at least 90% of the strings are
// translated in the corresponding language.
const List<Locale> appSupportedLocales = <Locale>[
  Locale('en'),
  Locale('es'),
  Locale('de'),
  Locale('fr'),
  Locale('it'),
  Locale('ja'),
  Locale("nl"),
  Locale("no"),
  Locale("pl"),
  Locale("pt", "BR"),
  Locale('pt', 'PT'),
  Locale("ro"),
  Locale("ru"),
  Locale("tr"),
  Locale("uk"),
  Locale("vi"),
  Locale("zh", "CN"),
];

List<Locale> _onDeviceLocales = [];
Locale? autoDetectedLocale;

Locale localResolutionCallBack(deviceLocales, supportedLocales) {
  _onDeviceLocales = deviceLocales;
  Locale? firstLangeuageMatch;
  for (Locale deviceLocale in deviceLocales) {
    for (Locale supportedLocale in appSupportedLocales) {
      if (supportedLocale == deviceLocale) {
        autoDetectedLocale = supportedLocale;
        return supportedLocale;
      }
      if (firstLangeuageMatch == null &&
          supportedLocale.languageCode == deviceLocale.languageCode) {
        firstLangeuageMatch = deviceLocale;
      }
    }
  }
  if (firstLangeuageMatch != null) {
    autoDetectedLocale = firstLangeuageMatch;
  }
  return autoDetectedLocale ?? const Locale('en');
}

// This is used to get locale that should be used for various formatting
// operations like date, time, number etc. For common languages like english, different
// locale might have different formats. For example, en_US and en_GB have different
// formats for date and time. Use this method to find the best locale for formatting
// operations. This is not used for displaying text in the app.
Future<Locale> getFormatLocale() async {
  final Locale locale = (await getLocale())!;
  Locale? firstLanguageMatch;
  // see if exact matche is present in the device locales
  for (Locale deviceLocale in _onDeviceLocales) {
    if (deviceLocale.languageCode == locale.languageCode &&
        deviceLocale.countryCode == locale.countryCode) {
      return deviceLocale;
    }
    if (firstLanguageMatch == null &&
        deviceLocale.languageCode == locale.languageCode) {
      firstLanguageMatch = deviceLocale;
    }
  }
  return firstLanguageMatch ?? locale;
}

Future<Locale?> getLocale({
  bool noFallback = false,
}) async {
  final String? savedValue =
      (await SharedPreferences.getInstance()).getString('locale');
  // if savedLocale is not null and is supported by the app, return it
  if (savedValue != null) {
    late Locale savedLocale;
    if (savedValue.contains('_')) {
      final List<String> parts = savedValue.split('_');
      savedLocale = Locale(parts[0], parts[1]);
    } else {
      savedLocale = Locale(savedValue);
    }
    if (appSupportedLocales.contains(savedLocale)) {
      return savedLocale;
    }
  }
  if (autoDetectedLocale != null) {
    return autoDetectedLocale!;
  }
  if (noFallback) {
    return null;
  }
  return const Locale('en');
}

Future<void> setLocale(Locale locale) async {
  if (!appSupportedLocales.contains(locale)) {
    throw Exception('Locale $locale is not supported by the app');
  }
  final StringBuffer out = StringBuffer(locale.languageCode);
  if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
    out.write('_');
    out.write(locale.countryCode);
  }
  await (await SharedPreferences.getInstance())
      .setString('locale', out.toString());
}
