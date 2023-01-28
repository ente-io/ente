import 'package:ente_auth/models/code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("parseCodeFromRawData", () {
    final code1 = Code.fromRawData(
      "otpauth://totp/example%20finance%3Aee%40ff.gg?secret=ASKZNWOU6SVYAMVS",
    );
    expect(code1.issuer, "example finance");
    expect(code1.account, "ee@ff.gg");
    expect(code1.secret, "ASKZNWOU6SVYAMVS");
  });
}
