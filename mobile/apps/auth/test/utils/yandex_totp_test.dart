import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceService.instance.init();
  });

  tearDown(() {
    PreferenceService.instance.computeAndStoreTimeOffset(null);
  });

  test('generates Yandex OTPs from Aegis vectors', () {
    const testCases = [
      (
        pin: 'GUZDGOI',
        secret: '6SB2IKNM6OBZPAVBVTOHDKS4FAAAAAAADFUTQMBTRY',
        timestamp: 1641559648,
        expected: 'umozdicq',
      ),
      (
        pin: 'G42TQNQ',
        secret: 'LA2V6KMCGYMWWVEW64RNP3JA3IAAAAAAHTSG4HRZPI',
        timestamp: 1581064020,
        expected: 'oactmacq',
      ),
      (
        pin: 'G42TQNQ',
        secret: 'LA2V6KMCGYMWWVEW64RNP3JA3IAAAAAAHTSG4HRZPI',
        timestamp: 1581090810,
        expected: 'wemdwrix',
      ),
      (
        pin: 'GUZDCMBUHAYTEMJWGA4DMNZQGI',
        secret: 'JBGSAU4G7IEZG6OY4UAXX62JU4AAAAAAHTSG4HXU3M',
        timestamp: 1581091469,
        expected: 'dfrpywob',
      ),
      (
        pin: 'GUZDCMBUHAYTEMJWGA4DMNZQGI',
        secret: 'JBGSAU4G7IEZG6OY4UAXX62JU4AAAAAAHTSG4HXU3M',
        timestamp: 1581093059,
        expected: 'vunyprpd',
      ),
    ];

    for (final testCase in testCases) {
      PreferenceService.instance.computeAndStoreTimeOffset(
        testCase.timestamp * 1000000,
      );
      final code = Code.fromOTPAuthUrl(
        'otpauth://yaotp/Yandex:test?secret=${testCase.secret}&issuer=Yandex&pin=${testCase.pin}',
      );
      expect(getOTP(code), testCase.expected);
    }
  });
}
