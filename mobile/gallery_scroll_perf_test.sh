#!/bin/bash

# Make sure to go through home_gallery_scroll_test.dart and 
# fill in email and password.
# Specify destination directory for the perf results in perf_driver.dart.


export ENDPOINT="https://api.ente.io"

flutter drive \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/home_gallery_scroll_test.dart \
  --dart-define=endpoint=$ENDPOINT \
  --profile --flavor independent \
  --no-dds

exit $?
