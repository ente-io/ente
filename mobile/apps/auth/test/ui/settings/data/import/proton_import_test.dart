import 'dart:convert';
import 'dart:typed_data';

import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/ui/settings/data/import/proton_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

void main() {
  test('parses Proton Authenticator exports', () {
    final codes = parseProtonExport({
      'version': 1,
      'entries': [
        {
          'id': 'totp-id',
          'content': {
            'uri':
                'otpauth://totp/GitHub:alice?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA1&digits=6&period=30',
            'entry_type': 'Totp',
            'name': 'alice',
          },
          'note': 'work account',
        },
        {
          'id': 'steam-id',
          'content': {
            'uri': 'steam://STEAMSECRET',
            'entry_type': 'Steam',
            'name': 'Steam',
          },
          'note': 'gaming',
        },
      ],
    });

    expect(codes, hasLength(2));

    expect(codes[0].type, Type.totp);
    expect(codes[0].issuer, 'GitHub');
    expect(codes[0].account, 'alice');
    expect(codes[0].note, 'work account');

    expect(codes[1].type, Type.steam);
    expect(codes[1].issuer, 'Steam');
    expect(codes[1].secret, 'STEAMSECRET');
    expect(codes[1].note, 'gaming');
  });

  test('detects password protected Proton exports', () {
    final encryptedExport = _createEncryptedExport(
      jsonEncode({
        'version': 1,
        'entries': [
          {
            'id': 'totp-id',
            'content': {
              'uri':
                  'otpauth://totp/GitHub:alice?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA1&digits=6&period=30',
              'entry_type': 'Totp',
              'name': 'alice',
            },
          },
        ],
      }),
      password: 'secret',
    );

    expect(isEncryptedProtonExport(encryptedExport), isTrue);
  });

  test('decrypts password protected Proton exports', () {
    final encryptedExport = _createEncryptedExport(
      jsonEncode({
        'version': 1,
        'entries': [
          {
            'id': 'steam-id',
            'content': {
              'uri': 'steam://STEAMSECRET',
              'entry_type': 'Steam',
              'name': 'Steam',
            },
            'note': 'gaming',
          },
        ],
      }),
      password: 'secret',
    );

    final decryptedJson = decryptProtonExport(
      encryptedExport,
      password: 'secret',
    );
    final codes = parseProtonExport(decodeProtonExportJson(decryptedJson));

    expect(codes, hasLength(1));
    expect(codes.single.type, Type.steam);
    expect(codes.single.secret, 'STEAMSECRET');
    expect(codes.single.note, 'gaming');
  });
}

Map<String, dynamic> _createEncryptedExport(
  String plaintextExport, {
  required String password,
}) {
  final salt = Uint8List.fromList(List<int>.generate(16, (index) => index + 1));
  final nonce = Uint8List.fromList(
    List<int>.generate(12, (index) => index + 31),
  );
  final derivedKey = deriveProtonPasswordKeyForTesting(password, salt);

  final cipher = GCMBlockCipher(AESEngine())
    ..init(
      true,
      AEADParameters(
        KeyParameter(derivedKey),
        128,
        nonce,
        Uint8List.fromList(utf8.encode(protonExportAadForTesting)),
      ),
    );
  final encryptedBytes = cipher.process(
    Uint8List.fromList(utf8.encode(plaintextExport)),
  );
  final payload = Uint8List.fromList([...nonce, ...encryptedBytes]);

  return {
    'version': 1,
    'salt': base64Encode(salt),
    'content': base64Encode(payload),
  };
}
