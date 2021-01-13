# Super Logging

[![Sponsor](https://img.shields.io/badge/Sponsor-jaaga_labs-red.svg?style=for-the-badge)](https://www.jaaga.in/labs)

[![pub package](https://img.shields.io/pub/v/super_logging.svg?style=for-the-badge)](https://pub.dartlang.org/packages/super_logging)

This package lets you easily log to:
- stdout
- disk
- sentry.io

```dart
import 'package:super_logging/super_logging.dart';
import 'package:logging/logging.dart';

final logger = Logger("main");

main() async {
  // just call once, and let it handle the rest!
  await SuperLogging.main();
  
  logger.info("hello!");
}
```

(Above example will log to stdout and disk.)

## Logging to sentry.io

Just specify your sentry DSN.

```dart
SuperLogging.main(LogConfig(
  sentryDsn: 'https://xxxx@sentry.io/yyyy',
));
```

## Log uncaught errors

Just provide the contents of your `main()` function to super logging.

```dart
void main() {
  SuperLogging.main(LogConfig(
    body: _main,
  ));
}

void _main() {
  runApp(MyApp());
}
```

[Read the docs](https://pub.dev/documentation/super_logging/latest/super_logging/super_logging-library.html) to know about more customization options.
