import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getLocaleDisplayName', () {
    test('labels Chinese variants by region', () {
      expect(getLocaleDisplayName(const Locale('zh', 'CN')), '中文 (中国)');
      expect(getLocaleDisplayName(const Locale('zh', 'TW')), '中文 (台灣)');
      expect(getLocaleDisplayName(const Locale('zh', 'HK')), '中文 (香港)');
    });

    test('labels Chinese variants by script', () {
      expect(
        getLocaleDisplayName(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ),
        '中文 (简体)',
      );
      expect(
        getLocaleDisplayName(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
        '中文 (繁體)',
      );
    });

    test('keeps auth language selector labels', () {
      expect(getLocaleDisplayName(const Locale('ar')), 'العربية');
      expect(getLocaleDisplayName(const Locale('bg')), 'Български');
      expect(
        getLocaleDisplayName(const Locale('es', 'ES')),
        'Español (España)',
      );
      expect(getLocaleDisplayName(const Locale('fa')), 'فارسی');
      expect(getLocaleDisplayName(const Locale('fi')), 'Suomi');
      expect(getLocaleDisplayName(const Locale('he')), 'עברית');
      expect(getLocaleDisplayName(const Locale('id')), 'Bahasa Indonesia');
      expect(getLocaleDisplayName(const Locale('ko')), '한국어');
      expect(
        getLocaleDisplayName(const Locale('pt', 'BR')),
        'Português (Brasil)',
      );
      expect(getLocaleDisplayName(const Locale('sk')), 'Slovenčina');
      expect(getLocaleDisplayName(const Locale('sl')), 'Slovenščina');
    });
  });
}
