import 'dart:io';

import 'package:ente_ui/pages/base_home_page.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import "package:locker/l10n/l10n.dart";
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/metadata_updater_service.dart';
import 'package:locker/services/files/upload/file_upload_service.dart';
import 'package:locker/ui/components/file_upload_dialog.dart';
import 'package:locker/ui/pages/file_upload_screen.dart';
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
  Future<bool> addFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final selectedFiles = result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      if (selectedFiles.isNotEmpty) {
        return await uploadFiles(selectedFiles);
      }
    }

    return false;
  }

  Future<bool> uploadFiles(List<File> files) async {
    var didUpload = false;
    final progressDialog = createProgressDialog(
      context,
      context.l10n.uploadedFilesProgress(0, files.length),
    );

    try {
      final List<Future> futures = [];

      final collections = await CollectionService.instance.getCollections();
      final regularCollections = collections
          .where(
            (c) => (c.type != CollectionType.uncategorized &&
                c.type != CollectionType.favorites),
          )
          .toList();

      // Navigate to upload screen to get collection selection
      final uploadResult =
          await Navigator.of(context).push<FileUploadDialogResult>(
        MaterialPageRoute(
          builder: (context) => FileUploadScreen(
            files: files,
            collections: regularCollections,
            selectedCollection: selectedCollection,
          ),
        ),
      );

      // Handle both regular collections and uncategorized (empty set)
      final isUncategorizedUpload =
          uploadResult != null && uploadResult.selectedCollections.isEmpty;
      final isRegularUpload =
          uploadResult != null && uploadResult.selectedCollections.isNotEmpty;

      if (isUncategorizedUpload || isRegularUpload) {
        didUpload = true;
        if (isUncategorizedUpload) {
          // Get the uncategorized collection for upload
          final uncategorizedCollection = await CollectionService.instance
              .getOrCreateUncategorizedCollection();
          uploadResult.selectedCollections.add(uncategorizedCollection);
        }

        await progressDialog.show();

        int completedUploads = 0;
        for (final file in files) {
          final fileUploadFuture = FileUploader.instance
              .upload(file, uploadResult.selectedCollections.first);
          futures.add(fileUploadFuture);
          futures.add(
            fileUploadFuture.then((enteFile) async {
              completedUploads++;
              progressDialog.update(
                message: context.l10n
                    .uploadedFilesProgress(completedUploads, files.length),
              );
              // Add to additional collections if multiple were selected
              for (int cIndex = 1;
                  cIndex < uploadResult.selectedCollections.length;
                  cIndex++) {
                // Don't trigger a sync for each additional collection – do one
                // sync at the end after all files are processed.
                futures.add(
                  CollectionService.instance.addToCollection(
                    uploadResult.selectedCollections[cIndex],
                    enteFile,
                    runSync: false,
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
              completedUploads++;
              _logger.severe('File upload failed', e);
              progressDialog.update(
                message: context.l10n.uploadedFilesProgressWithError(
                  completedUploads,
                  files.length,
                  e.toString(),
                ),
              );
            }),
          );
        }

        if (futures.isNotEmpty) {
          await Future.wait(futures);

          onFileUploadComplete();

          await CollectionService.instance.sync().catchError((e) {
            _logger.warning('Background sync failed after upload', e);
          });
        }
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

    return didUpload;
  }
}
