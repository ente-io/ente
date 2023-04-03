import 'package:ente_auth/models/code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("parseCodeFromRawData", () {
    final code1 = Code.fromRawData(
      "otpauth://totp/example%20finance%3Aee%40ff.gg?secret=ASKZNWOU6SVYAMVS",
    );
    expect(code1.issuer, "example finance", reason: "issuerMismatch");
    expect(code1.account, "ee@ff.gg", reason: "accountMismatch");
    expect(code1.secret, "ASKZNWOU6SVYAMVS");
  });

  test("parseDocumentedFormat", () {
    final code = Code.fromRawData(
      "otpauth://totp/testdata@ente.io?secret=ASKZNWOU6SVYAMVS&issuer=GitHub",
    );
    expect(code.issuer, "GitHub", reason: "issuerMismatch");
    expect(code.account, "testdata@ente.io", reason: "accountMismatch");
    expect(code.secret, "ASKZNWOU6SVYAMVS");
  });
}
