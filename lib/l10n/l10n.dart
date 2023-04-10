import "package:flutter/widgets.dart";
import "package:photos/generated/l10n.dart";

extension AppLocalizationsX on BuildContext {
  S get l10n => S.of(this);
}

// list of locales which are enabled for auth app.
// Add more language to the list only when at least 90% of the strings are
// translated in the corresponding language.
const List<Locale> appSupportedLocales = <Locale>[
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
