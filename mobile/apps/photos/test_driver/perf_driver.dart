import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

///https://api.flutter.dev/flutter/flutter_driver/TimelineSummary/summaryJson.html

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data != null) {
        final timeline = driver.Timeline.fromJson(
          data['*`report_key` of traceAction of integration test*']
              as Map<String, dynamic>,
        );

        final summary = driver.TimelineSummary.summarize(timeline);

        await summary.writeTimelineToFile(
          '*title of file*',
          pretty: true,
          includeSummary: true,
          //Specify destination directory for the timeline files.
        );
      }
    },
  );
}
