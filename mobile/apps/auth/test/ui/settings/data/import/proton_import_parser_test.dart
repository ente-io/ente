import 'dart:io';

import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/ui/settings/data/import/proton_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Proton import parser', () {
    test('parses plaintext Proton exports from fixture', () async {
      final exportJson = decodeProtonExportJson(
        await _fixture('proton_authenticator_backup.json').readAsString(),
      );

      final codes = parseProtonExport(exportJson);

      expect(codes, hasLength(4));

      expect(codes.first.type, Type.totp);
      expect(codes.first.issuer, 'Userlane Realm');
      expect(codes.first.account, 'sean.hickey+2fa@userlane.com');

      expect(codes[1].issuer, 'john.appleseed@example.org');
      expect(codes[1].account, 'john.appleseed@example.org');

      expect(codes[2].issuer, 'Simplesat');
      expect(codes[2].account, 'ravin@prontomarketing.com');

      expect(codes[3].issuer, 'Gemini');
      expect(codes[3].account, 'dele@countersoft.com');
    });

    test('decrypts password protected Proton exports from fixture', () async {
      final encryptedJson = decodeProtonExportJson(
        await _fixture(
          'proton_authenticator_backup_encrypted_1231246.json',
        ).readAsString(),
      );

      expect(isEncryptedProtonExport(encryptedJson), isTrue);

      final decryptedJson = decryptProtonExport(
        encryptedJson,
        password: '1231246',
      );
      final codes = parseProtonExport(decodeProtonExportJson(decryptedJson));

      expect(codes, hasLength(4));
      expect(codes.first.issuer, 'Userlane Realm');
      expect(codes.last.issuer, 'Gemini');
    });

    test('fails to decrypt password protected Proton exports with bad password',
        () async {
      final encryptedJson = decodeProtonExportJson(
        await _fixture(
          'proton_authenticator_backup_encrypted_1231246.json',
        ).readAsString(),
      );

      expect(
        () => decryptProtonExport(encryptedJson, password: 'wrong-password'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

File _fixture(String name) => File(
      'test/ui/settings/data/import/fixtures/$name',
    );
