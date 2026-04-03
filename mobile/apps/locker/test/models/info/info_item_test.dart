import 'package:flutter_test/flutter_test.dart';
import 'package:locker/models/info/info_item.dart';

void main() {
  group('InfoTypeExtension', () {
    test('serializes info types to hyphenated wire values', () {
      expect(InfoType.note.value, 'note');
      expect(InfoType.physicalRecord.value, 'physical-record');
      expect(InfoType.accountCredential.value, 'account-credential');
      expect(InfoType.emergencyContact.value, 'emergency-contact');
    });

    test('parses both hyphenated and camelCase values', () {
      expect(InfoTypeExtension.fromString('note'), InfoType.note);
      expect(
        InfoTypeExtension.fromString('physical-record'),
        InfoType.physicalRecord,
      );
      expect(
        InfoTypeExtension.fromString('physicalRecord'),
        InfoType.physicalRecord,
      );
      expect(
        InfoTypeExtension.fromString('account-credential'),
        InfoType.accountCredential,
      );
      expect(
        InfoTypeExtension.fromString('accountCredential'),
        InfoType.accountCredential,
      );
      expect(
        InfoTypeExtension.fromString('emergency-contact'),
        InfoType.emergencyContact,
      );
      expect(
        InfoTypeExtension.fromString('emergencyContact'),
        InfoType.emergencyContact,
      );
    });

    test('round-trips info item JSON with hyphenated wire types', () {
      final item = InfoItem(
        type: InfoType.accountCredential,
        data: AccountCredentialData(
          name: 'GitHub',
          username: 'octocat',
          password: 'secret',
        ),
        createdAt: DateTime.parse('2026-04-03T12:00:00Z'),
      );

      final json = item.toJson();

      expect(json['type'], 'account-credential');
      expect(InfoItem.fromJson(json).type, InfoType.accountCredential);

      final camelCaseJson = {
        ...json,
        'type': 'accountCredential',
      };
      expect(InfoItem.fromJson(camelCaseJson).type, InfoType.accountCredential);
    });
  });
}
