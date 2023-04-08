import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

// list of locales which are enabled for auth app.
// Add more language to the list only when at least 90% of the strings are
// translated in the corresponding language.
const List<Locale> appSupportedLocales = <Locale>[
  Locale('en'),
  Locale('de'),
  Locale('fr'),
  Locale('it'),
];

Locale localResolutionCallBack(locales, supportedLocales) {
  // print call stacktrace to identify caller
  for (Locale locale in locales) {
    if (appSupportedLocales.contains(locale)) {
      return locale;
    }
  }
  // if device language is not supported by the app, use en as default
  return const Locale('en');
}

Future<Locale> getLocale() async {
  final String? savedLocale =
      (await SharedPreferences.getInstance()).getString('locale');
  if (savedLocale != null &&
      appSupportedLocales.contains(Locale(savedLocale))) {
    return Locale(savedLocale);
  }
  return const Locale('en');
}

Future<void> setLocale(Locale locale) async {
  if (!appSupportedLocales.contains(locale)) {
    throw Exception('Locale $locale is not supported by the app');
  }
  await (await SharedPreferences.getInstance())
      .setString('locale', locale.languageCode);
}
