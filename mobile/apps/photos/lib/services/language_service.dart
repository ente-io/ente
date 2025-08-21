import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";

class LanguageService {
  static Future<AppLocalizations> get locals async {
    final local = await getLocale();
    final s = lookupAppLocalizations(local!);
    return s;
  }
}
