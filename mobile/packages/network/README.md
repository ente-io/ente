# Ente Network

A Flutter package for network management and HTTP client configuration used across Ente applications.

## Features

- Configurable HTTP client using Dio
- Request interceptors for authentication and request tracking
- Platform-aware user agent handling
- Connection timeout management
- Base URL configuration
- Request ID generation

## Usage

```dart
import 'package:ente_network/network.dart';
import 'package:ente_configuration/base_configuration.dart';

// Initialize the network service
await Network.instance.init(configuration);

// Use the configured Dio instances
final dio = Network.instance.getDio();
final enteDio = Network.instance.enteDio;
```

## Dependencies

This package depends on:
- `dio` for HTTP client functionality
- `ente_configuration` for configuration management
- `ente_events` for event handling
- `native_dio_adapter` for native networking
- `package_info_plus` for package information
- `ua_client_hints` for user agent generation
- `uuid` for request ID generation
