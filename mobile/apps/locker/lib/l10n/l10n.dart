import "package:flutter/widgets.dart";
import 'package:locker/l10n/app_localizations.dart';

export "app_localizations.dart";

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
