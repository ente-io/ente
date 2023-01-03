import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/file/file_info_collection_widget.dart';

class DeviceFoldersListOfFileWidget extends StatelessWidget {
  final Future<Set<String>> allDeviceFoldersOfFile;
  const DeviceFoldersListOfFileWidget(this.allDeviceFoldersOfFile, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Set<String>>(
      future: allDeviceFoldersOfFile,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<String> deviceFolders = snapshot.data!.toList();
          return ListView.builder(
            itemCount: deviceFolders.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return FileInfoCollectionWidget(
                name: deviceFolders[index],
                onTap: () {},
              );
            },
          );
        } else if (snapshot.hasError) {
          Logger("DeviceFoldersListOfFile").info(snapshot.error);
          return const SizedBox.shrink();
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }
}
