#!/bin/sh

FLUTTER_RUN="flutter run --flavor dev "

if [ ! -z "$1" ]
then
    SUPPLIED_ENV_FILE="$1"
    while IFS= read -r line
    do
      FLUTTER_RUN="$FLUTTER_RUN --dart-define $line"

    done < "$SUPPLIED_ENV_FILE"
fi
echo "Running: $FLUTTER_RUN"
$FLUTTER_RUN
