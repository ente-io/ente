import 'package:ente_auth/ui/code_widget_layout_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldShowNextTotpCode', () {
    test('returns false for constrained width and large text scale', () {
      final value = shouldShowNextTotpCode(
        isIOS: false,
        availableWidth: 260,
        textScaleFactor: 1.4,
        isCompactMode: false,
      );

      expect(value, isFalse);
    });

    test('returns true for comfortable width', () {
      final value = shouldShowNextTotpCode(
        isIOS: false,
        availableWidth: 420,
        textScaleFactor: 1.0,
        isCompactMode: false,
      );

      expect(value, isTrue);
    });

    test('returns true on iOS regardless of width', () {
      final value = shouldShowNextTotpCode(
        isIOS: true,
        availableWidth: 260,
        textScaleFactor: 3.12,
        isCompactMode: false,
      );

      expect(value, isTrue);
    });
  });
}
