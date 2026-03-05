import "dart:io";

import "package:integration_test/integration_test_driver.dart";

const _parityReportDataKey = "ml_parity_results_json";
const _driverOutputEnvKey = "ML_PARITY_DRIVER_OUTPUT";

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      final outputPath = Platform.environment[_driverOutputEnvKey]?.trim();
      if (outputPath == null || outputPath.isEmpty) {
        throw StateError(
          "Missing $_driverOutputEnvKey environment variable for parity driver output path",
        );
      }
      if (data == null) {
        throw StateError("Integration test returned null response data");
      }

      final payload = data[_parityReportDataKey];
      if (payload is! String || payload.isEmpty) {
        throw StateError(
          "Missing parity report data key '$_parityReportDataKey'",
        );
      }

      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsString("$payload\n");
      stdout.writeln("ML parity output written to $outputPath");
    },
  );
}
