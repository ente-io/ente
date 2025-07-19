import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:ente_strings/ente_strings.dart';

void main() {
  group('StringsLocalizations', () {
    test('should include English locale', () {
      expect(
        StringsLocalizations.supportedLocales,
        contains(const Locale('en')),
      );
    });

    test('should include multiple locales', () {
      expect(StringsLocalizations.supportedLocales.length, greaterThan(10));

      // Check for some key languages
      expect(
        StringsLocalizations.supportedLocales,
        contains(const Locale('fr')),
      );
      expect(
        StringsLocalizations.supportedLocales,
        contains(const Locale('ja')),
      );
      expect(
        StringsLocalizations.supportedLocales,
        contains(const Locale('zh')),
      );
    });
  });
}
