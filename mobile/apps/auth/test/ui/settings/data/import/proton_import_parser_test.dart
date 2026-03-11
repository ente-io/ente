import 'dart:io';

import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/ui/settings/data/import/proton_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Proton import parser', () {
    test('parses plaintext Proton exports from fixture', () async {
      final codes = await _loadPlaintextFixtureCodes();

      expect(codes, hasLength(4));
      _assertCode(
        codes[0],
        type: Type.totp,
        issuer: '.env',
        account: 'example@ente.io',
        secret: 'MI4GCOJSGIZTKLJSGMZWKLJUGEZDQLJYG5STILJSMUYDIYTCMQ3TSOJRGI',
        algorithm: Algorithm.sha1,
        digits: 6,
        period: 30,
      );
      _assertCode(
        codes[1],
        type: Type.totp,
        issuer: '/e/',
        account: 'cool@ente.com',
        secret: '554VBDOGJRLDG2JV',
        algorithm: Algorithm.sha1,
        digits: 6,
        period: 30,
      );
      _assertCode(
        codes[2],
        type: Type.totp,
        issuer: 'ente',
        account: 'simple@ente.sh',
        secret: 'PIBTGMBYQYVSLN5PVZYQUTKYHOBRYYT7',
        algorithm: Algorithm.sha1,
        digits: 6,
        period: 30,
      );
      _assertCode(
        codes[3],
        type: Type.totp,
        issuer: 'reddit',
        account: 'r@ente.com',
        secret: 'J4YFC3TZKVYWCVCNIVBWIV2GHFAXUNDF',
        algorithm: Algorithm.sha1,
        digits: 6,
        period: 30,
      );
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
      final decryptedCodes =
          parseProtonExport(decodeProtonExportJson(decryptedJson));
      final plaintextCodes = await _loadPlaintextFixtureCodes();

      expect(decryptedCodes, hasLength(4));
      expect(decryptedCodes, hasLength(plaintextCodes.length));
      for (var index = 0; index < plaintextCodes.length; index++) {
        expect(decryptedCodes[index], plaintextCodes[index]);
      }
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
        throwsA(isA<IncorrectProtonExportPasswordException>()),
      );
    });
  });
}

Future<List<Code>> _loadPlaintextFixtureCodes() async {
  final exportJson = decodeProtonExportJson(
    await _fixture('proton_authenticator_backup.json').readAsString(),
  );
  return parseProtonExport(exportJson);
}

void _assertCode(
  Code code, {
  required Type type,
  required String issuer,
  required String account,
  required String secret,
  required Algorithm algorithm,
  required int digits,
  required int period,
}) {
  expect(code.type, type);
  expect(code.issuer, issuer);
  expect(code.account, account);
  expect(code.secret, secret);
  expect(code.algorithm, algorithm);
  expect(code.digits, digits);
  expect(code.period, period);
}

File _fixture(String name) => File(
      'test/ui/settings/data/import/fixtures/$name',
    );
