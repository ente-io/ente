import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";

class LanguageService {
  static Future<S> get s async {
    try {
      return S.current;
    } catch (_) {}

    final local = await getLocale();

    final s = await S.load(local!);

    return s;
  }
}
