import 'package:flutter/material.dart';
import 'package:photos/models/offline_file.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/theme/ente_theme.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  late List<OfflineFile> _offlineFiles;

  @override
  void initState() {
    super.initState();
    _offlineFiles = offlineFileService.getOfflineFiles();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Offline',
          style: TextStyle(color: colorScheme.textBase),
        ),
        backgroundColor: colorScheme.surface,
        iconTheme: IconThemeData(color: colorScheme.textBase),
      ),
      body: ListView.builder(
        itemCount: _offlineFiles.length,
        itemBuilder: (context, index) {
          final offlineFile = _offlineFiles[index];
          return ListTile(
            title: Text(offlineFile.originalFile.fileName),
            subtitle: Text(offlineFile.localPath),
          );
        },
      ),
    );
  }
}
