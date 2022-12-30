import 'package:flutter/cupertino.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';

class FileSelectionCommonActionWidget extends StatelessWidget {
  final GalleryType type;
  final SelectedFiles selectedFiles;

  const FileSelectionCommonActionWidget({
    super.key,
    required this.type,
    required this.selectedFiles,
  });
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
