# Log Viewer

A Flutter package that provides an in-app log viewer with advanced filtering capabilities for Ente apps.

## Features

- 📝 Real-time log capture and display
- 🔍 Advanced filtering by logger name, log level, and text search
- 🎨 Color-coded log levels for easy identification
- 📊 SQLite-based storage with automatic truncation
- 📤 Export filtered logs as text
- ⚡ Performance optimized with batch inserts and indexing

## Usage

### 1. Initialize in your app

```dart
import 'package:log_viewer/log_viewer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize log viewer
  await LogViewer.initialize();
  
  runApp(MyApp());
}
```

### 2. Open the log viewer

```dart
// As a navigation action
LogViewer.openViewer(context);

// Or embed as a widget
LogViewer.getViewerPage()
```

### 3. The log viewer will automatically capture all logs

The package integrates with the Ente logging system to automatically capture and store logs.

## Filtering Options

- **Logger Name**: Filter by specific loggers (e.g., "auth", "sync", "ui")
- **Log Level**: Filter by severity (SEVERE, WARNING, INFO, etc.)
- **Text Search**: Search within log messages and error descriptions
- **Time Range**: Filter logs by date/time range

## Database Management

- Logs are stored in a local SQLite database
- By default, automatic truncation keeps only the most recent 10000 entries
- Batch inserts for optimal performance
