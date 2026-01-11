import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/services/offline_download_service.dart';
import 'package:photos/ui/viewer/file/detail_page.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';

class OfflineGalleryScreen extends StatefulWidget {
  const OfflineGalleryScreen({super.key});

  @override
  State<OfflineGalleryScreen> createState() => _OfflineGalleryScreenState();
}

class _OfflineGalleryScreenState extends State<OfflineGalleryScreen> {
  late Future<List<EnteFile>> _filesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _filesFuture = FilesDB.instance.getOfflineAvailableFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Gallery'),
      ),
      body: FutureBuilder<List<EnteFile>>(
        future: _filesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final files = snapshot.data ?? [];
          if (files.isEmpty) {
            return const Center(child: Text('No offline files'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(
                        DetailPageConfiguration(
                          files,
                          index,
                          "offline_gallery",
                        ),
                      ),
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ThumbnailWidget(file),
                    FutureBuilder<File?>(
                      future: OfflineDownloadService.instance.getOfflineFile(
                        file,
                      ),
                      builder: (context, fileSnapshot) {
                        if (fileSnapshot.hasData && fileSnapshot.data != null) {
                          return const Positioned(
                            right: 4,
                            bottom: 4,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
