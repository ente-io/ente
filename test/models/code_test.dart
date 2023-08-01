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

  test("validateCount", () {
    final code = Code.fromRawData(
      "otpauth://hotp/testdata@ente.io?secret=ASKZNWOU6SVYAMVS&issuer=GitHub&counter=15",
    );
    expect(code.issuer, "GitHub", reason: "issuerMismatch");
    expect(code.account, "testdata@ente.io", reason: "accountMismatch");
    expect(code.secret, "ASKZNWOU6SVYAMVS");
    expect(code.counter, 15);
  });
//

  test("parseWithFunnyAccountName", () {
    final code = Code.fromRawData(
      "otpauth://totp/Mongo Atlas:Acc !@#444?algorithm=sha1&digits=6&issuer=Mongo Atlas&period=30&secret=NI4CTTFEV4G2JFE6",
    );
    expect(code.issuer, "Mongo Atlas", reason: "issuerMismatch");
    expect(code.account, "Acc !@#444", reason: "accountMismatch");
    expect(code.secret, "NI4CTTFEV4G2JFE6");
  });
}
