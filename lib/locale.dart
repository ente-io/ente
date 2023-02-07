import 'dart:ui';

// list of locales which are enabled for auth app.
// Add more language to the list only when at least 90% of the strings are
// translated in the corresponding language.
const List<Locale> supportedLocales = <Locale>[
  Locale('en'),
];

Locale localResolutionCallBack(locales, supportedLocales) {
  for (Locale locale in locales) {
    if (supportedLocales.contains(locale)) {
      return locale;
    }
  }
  // if device language is not supported by the app, use en as default
  return const Locale('en');
}
