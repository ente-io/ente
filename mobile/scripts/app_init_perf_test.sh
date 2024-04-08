#!/bin/bash

# Make sure to go through app_init_test.dart and 
# fill in email and password.
# Specify destination directory for the perf results in perf_driver.dart.
# Specify the report_key of the test in perf_driver.dart. `report_key`` of
# `traceAction`` in app_init_test.dart.

# On first run, app will start from login page. from second run onwards, 
# app will start from home page. --keep-app-running is for starting the 
# app from home page instead of logging in on every run.

export ENDPOINT="https://api.ente.io"

flutter drive \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/app_init_test.dart \
  --dart-define=endpoint=$ENDPOINT \
  --profile --flavor independent \
  --no-dds \
  --keep-app-running

exit $?
