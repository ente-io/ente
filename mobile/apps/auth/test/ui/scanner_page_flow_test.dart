import 'package:ente_auth/ui/scanner_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldHandleScanResult', () {
    test('returns false after first successful handling', () {
      final first = shouldHandleScanResult(
        hasHandledResult: false,
        scannedCode: 'otpauth://totp/test?secret=ABC',
      );
      final second = shouldHandleScanResult(
        hasHandledResult: true,
        scannedCode: 'otpauth://totp/test?secret=ABC',
      );

      expect(first, isTrue);
      expect(second, isFalse);
    });

    test('returns false for null scan content', () {
      final value = shouldHandleScanResult(
        hasHandledResult: false,
        scannedCode: null,
      );

      expect(value, isFalse);
    });
  });
}
