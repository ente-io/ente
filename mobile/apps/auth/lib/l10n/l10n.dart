import "package:ente_auth/l10n/arb/app_localizations.dart"
    show AppLocalizations;
import "package:flutter/widgets.dart";
export "package:ente_auth/l10n/arb/app_localizations.dart"
    show AppLocalizations;

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
