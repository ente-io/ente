import "dart:ui";

class ChangeLogStrings {
  final String sheetTitle;
  final String sheetSubtitle;
  final String continueLabel;
  final String title1;
  final String desc1;
  final String title2;
  final String desc2;
  final String title3;
  final String desc3;

  const ChangeLogStrings({
    required this.sheetTitle,
    required this.sheetSubtitle,
    required this.continueLabel,
    required this.title1,
    required this.desc1,
    required this.title2,
    required this.desc2,
    required this.title3,
    required this.desc3,
  });

  static ChangeLogStrings forLocale(Locale locale) {
    final key = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? "${locale.languageCode}_${locale.countryCode}"
        : locale.languageCode;

    return _translations[key] ??
        _translations[locale.languageCode] ??
        _translations["en"]!;
  }

  static const Map<String, ChangeLogStrings> _translations = {
    "en": ChangeLogStrings(
      sheetTitle: "What's new",
      sheetSubtitle: "",
      continueLabel: "Continue",
      title1: "Share collections as a link",
      desc1:
          "You can now share any collection as a link. This includes password protection, device limits, and link expiry.",
      title2: "Keep items offline",
      desc2:
          "Keep your important items available locally for offline use. They stay encrypted on your device and are decrypted only when you open them in Locker.",
      title3: "",
      desc3: "",
    ),
  };
}
