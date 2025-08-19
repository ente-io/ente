import 'dart:io';

import 'package:ente_ui/pages/base_home_page.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/metadata_updater_service.dart';
import 'package:locker/services/files/upload/file_upload_service.dart';
import 'package:locker/ui/components/file_upload_dialog.dart';
import 'package:logging/logging.dart';

/// Abstract base class that provides file upload functionality.
/// Contains common file picking and uploading logic that can be reused
/// across different pages like HomePage and CollectionPage.
abstract class UploaderPage extends BaseHomePage {
  const UploaderPage({super.key});
}

abstract class UploaderPageState<T extends UploaderPage> extends State<T> {
  final _logger = Logger('UploaderPage');

  /// Returns the collection that should be pre-selected in the upload dialog.
  /// Return null to default to uncategorized collection.
  Collection? get selectedCollection => null;

  /// Called after a successful file upload to refresh the UI
  void onFileUploadComplete();

  /// Opens a file picker dialog and uploads the selected file
  Future<void> addFile() async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.isNotEmpty) {
      final selectedFile = result.files.first;
      if (selectedFile.path != null) {
        await uploadFile(File(selectedFile.path!));
      }
    }
  }

  Future<void> uploadFile(File file) async {
    final progressDialog = createProgressDialog(context, "Uploading...");
    try {
      final List<Future> futures = [];

      final collections = await CollectionService.instance.getCollections();

      final collectionsWithoutUncategorized = collections
          .where((c) => c.type != CollectionType.uncategorized)
          .toList();

      final uploadResult = await showFileUploadDialog(
        context,
        file: file,
        collections: collectionsWithoutUncategorized,
        selectedCollection: selectedCollection,
      );

      if (uploadResult != null && uploadResult.selectedCollections.isNotEmpty) {
        final fileUploadFuture = FileUploader.instance
            .upload(file, uploadResult.selectedCollections.first);
        futures.add(fileUploadFuture);
        futures.add(
          fileUploadFuture.then((enteFile) async {
            // Add to additional collections if multiple were selected
            for (int cIndex = 1;
                cIndex < uploadResult.selectedCollections.length;
                cIndex++) {
              futures.add(
                CollectionService.instance.addToCollection(
                  uploadResult.selectedCollections[cIndex],
                  enteFile,
                ),
              );
            }

            if (uploadResult.note.isNotEmpty) {
              futures.add(
                MetadataUpdaterService.instance
                    .editFileCaption(enteFile, uploadResult.note),
              );
            }
          }).catchError((e) {
            _logger.severe('File upload failed', e);
          }),
        );
      }

      if (futures.isNotEmpty) {
        await progressDialog.show();
        await Future.wait(futures);
        _logger.info('File upload completed successfully');
        await CollectionService.instance.sync();
        onFileUploadComplete();
      }
    } catch (e, s) {
      _logger.severe('Failed to upload file', e, s);
      await showGenericErrorDialog(
        context: context,
        error: e,
      );
    } finally {
      if (progressDialog.isShowing()) {
        await progressDialog.hide();
      }
    }
  }
}
