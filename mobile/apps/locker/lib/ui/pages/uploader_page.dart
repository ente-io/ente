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
        await uploadFiles(selectedFiles);
      }
    }
  }

  Future<void> uploadFiles(List<File> files) async {
    final progressDialog = createProgressDialog(
      context,
      context.l10n.uploadedFilesProgress(0, files.length),
    );

    try {
      final List<Future> futures = [];

      final collections = await CollectionService.instance.getCollections();

      final collectionsWithoutUncategorized = collections
          .where((c) => c.type != CollectionType.uncategorized)
          .toList();

      // Show upload dialog for the first file to get collection selection
      final uploadResult = await showFileUploadDialog(
        context,
        file: files.first,
        collections: collectionsWithoutUncategorized,
        selectedCollection: selectedCollection,
      );

      if (uploadResult != null && uploadResult.selectedCollections.isNotEmpty) {
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
      }
      if (futures.isNotEmpty) {
        await progressDialog.show();
        await Future.wait(futures);

        // Sync once at the end when files are added to multiple collections
        final shouldPerformFinalSync = (uploadResult != null &&
            uploadResult.selectedCollections.length > 1);

        if (shouldPerformFinalSync) {
          // Final sync triggers UI refresh via CollectionsUpdatedEvent
          await CollectionService.instance.sync();
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
  }
}
