import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:photos/generated/l10n.dart";
import "package:shared_preferences/shared_preferences.dart";

extension AppLocalizationsX on BuildContext {
  S get l10n => S.of(this);
}

// list of locales which are enabled for auth app.
// Add more language to the list only when at least 90% of the strings are
// translated in the corresponding language.
const List<Locale> appSupportedLocales = kDebugMode
    ? <Locale>[Locale('en'), Locale('fr'), Locale("nl")]
    : <Locale>[
        Locale('en'),
      ];

Locale localResolutionCallBack(locales, supportedLocales) {
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
