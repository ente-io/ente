#!/bin/sh

FLUTTER_RUN="flutter run --flavor dev "

SUPPLIED_ENV_FILE=".env"
while IFS= read -r line
do
    FLUTTER_RUN="$FLUTTER_RUN --dart-define $line"

done < "$SUPPLIED_ENV_FILE"

echo "Running: $FLUTTER_RUN"
$FLUTTER_RUN
