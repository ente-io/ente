# Configuration

A Flutter package for shared configuration across ente apps.

## Usage

Import the package and call the init method from your app's main.dart:

```dart
import 'package:configuration/configuration.dart';

void main() async {
  await Configuration.init();
  // ... rest of your app initialization
}
```

## Features

- Shared configuration initialization
- Common setup logic for ente apps
