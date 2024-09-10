import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

// list of locales which are enabled for auth app.
// Add more language to the list only when at least 90% of the strings are
// translated in the corresponding language.
const List<Locale> appSupportedLocales = <Locale>[
  Locale('de'),
  Locale('en'),
  Locale('es', 'ES'),
  Locale('fa'),
  Locale('fr'),
  Locale('it'),
  Locale('ja'),
  Locale('nl'),
  Locale('pl'),
  Locale('pt', 'BR'),
  Locale('ru'),
  Locale('tr'),
  Locale('uk'),
  Locale("zh", "CN"),
];

Locale localResolutionCallBack(locales, supportedLocales) {
  Locale? languageCodeMatch;
  final Map<String, Locale> languageCodeToLocale = {
    for (Locale supportedLocale in appSupportedLocales)
      supportedLocale.languageCode: supportedLocale,
  };

  for (Locale locale in locales) {
    if (appSupportedLocales.contains(locale)) {
      return locale;
    }

    if (languageCodeMatch == null &&
        languageCodeToLocale.containsKey(locale.languageCode)) {
      languageCodeMatch = languageCodeToLocale[locale.languageCode];
    }
  }

  // Return the first language code match or default to 'en'
  return languageCodeMatch ?? const Locale('en');
}

Future<Locale> getLocale() async {
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
