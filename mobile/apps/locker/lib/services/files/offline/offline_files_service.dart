import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ente_events/event_bus.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/events/collections_updated_event.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/services/db/locker_db.dart';
import 'package:locker/services/files/download/file_downloader.dart';
import 'package:locker/services/files/offline/offline_file_storage.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/info_file_service.dart';
import 'package:logging/logging.dart';

enum _OfflineSaveFailureKind {
  generic,
  network,
  storage,
}

/// Handles Locker's explicit per-file offline save flow.
///
/// A file is marked offline only after the encrypted blob has been saved on
/// this device.
class OfflineFilesService {
  OfflineFilesService._privateConstructor();

  static const _cachedFileCleanupAge = Duration(hours: 12);

  static final OfflineFilesService instance =
      OfflineFilesService._privateConstructor();

  final Logger _logger = Logger('OfflineFilesService');

  Future<void> init() async {
    _logger.fine('Cleaning up stale offline working files');
    await cleanupOfflineWorkingFiles(
      olderThan: _cachedFileCleanupAge,
    );
  }

  /// Shared files and info records are intentionally excluded from offline save.
  bool canMarkOffline(EnteFile file) {
    final currentUserID = Configuration.instance.getUserID();
    return file.uploadedFileID != null &&
        file.fileDecryptionHeader != null &&
        file.ownerID == currentUserID &&
        !InfoFileService.instance.isInfoFile(file);
  }

  /// Deduplicate selections by uploaded file ID so bulk actions only process
  /// each file once.
  List<EnteFile> getEligibleFiles(Iterable<EnteFile> files) {
    final filesById = <int, EnteFile>{};

    for (final file in files) {
      final fileId = file.uploadedFileID;
      if (fileId == null || !canMarkOffline(file)) {
        continue;
      }
      filesById[fileId] = file;
    }

    return filesById.values.toList();
  }

  /// Count shared files for UI messaging while still allowing owned files in
  /// the same selection to continue.
  int countSharedFiles(Iterable<EnteFile> files) {
    final currentUserID = Configuration.instance.getUserID();
    var sharedCount = 0;
    final seenFileIDs = <int>{};

    for (final file in files) {
      final fileId = file.uploadedFileID;
      if (fileId == null || !seenFileIDs.add(fileId)) {
        continue;
      }
      if (InfoFileService.instance.isInfoFile(file)) {
        continue;
      }
      if (file.ownerID != null && file.ownerID != currentUserID) {
        sharedCount += 1;
      }
    }

    return sharedCount;
  }

  bool hasEligibleFiles(Iterable<EnteFile> files) {
    return getEligibleFiles(files).isNotEmpty;
  }

  /// The bottom sheet only shows "Remove offline" when every actionable
  /// file in the selection is already marked offline on this device.
  bool shouldRemoveOfflineForSelection(Iterable<EnteFile> files) {
    final eligibleFiles = getEligibleFiles(files);
    if (eligibleFiles.isEmpty) {
      return false;
    }
    return eligibleFiles.every(LockerDB.instance.isFileMarkedOffline);
  }

  /// Downloads the encrypted blob and marks the file offline on success.
  Future<bool> markFilesOffline(
    BuildContext context,
    Iterable<EnteFile> files,
  ) async {
    final eligibleFiles = getEligibleFiles(files);
    final sharedCount = countSharedFiles(files);
    _logger.info(
      'Mark offline requested for ${eligibleFiles.length} eligible files'
      '${sharedCount > 0 ? ' ($sharedCount shared skipped)' : ''}',
    );

    if (sharedCount > 0 && context.mounted) {
      showToast(
        context,
        context.l10n.actionNotSupportedForSharedFiles(sharedCount),
      );
    }

    if (eligibleFiles.isEmpty || !context.mounted) {
      _logger.fine('No eligible files to mark offline');
      return false;
    }

    final total = eligibleFiles.length;
    final dialog = createProgressDialog(
      context,
      total == 1
          ? context.l10n.savingOffline
          : '${context.l10n.savingOffline} 0/$total',
      isDismissible: false,
    );

    var successCount = 0;
    var failureCount = 0;
    final failureKinds = <_OfflineSaveFailureKind>{};

    await dialog.show();

    try {
      for (var index = 0; index < eligibleFiles.length; index++) {
        final file = eligibleFiles[index];
        final fileID = file.uploadedFileID!;
        final currentStep = index + 1;

        dialog.update(
          message: _buildMarkProgressMessage(
            context,
            currentStep,
            total,
          ),
        );

        final alreadyHasOfflineCopy =
            LockerDB.instance.isFileMarkedOffline(file) &&
            await getCurrentOfflineEncryptedCopy(file) != null;
        if (alreadyHasOfflineCopy) {
          _logger.fine('File $fileID already available offline');
          successCount += 1;
          continue;
        }

        try {
          final didMarkFile = await _ensureOfflineCopyAndMark(
            file,
            progressCallback: (downloaded, totalBytes) {
              if (!context.mounted || totalBytes <= 0) {
                return;
              }
              final percentage =
                  ((downloaded / totalBytes) * 100).clamp(0, 100).round();
              dialog.update(
                message: _buildMarkProgressMessage(
                  context,
                  currentStep,
                  total,
                  percentage: percentage,
                ),
              );
            },
          );
          if (didMarkFile) {
            _logger.info('Marked file $fileID available offline');
            successCount += 1;
            continue;
          }

          failureCount += 1;
          failureKinds.add(_OfflineSaveFailureKind.generic);
        } catch (e, s) {
          final failureKind = _classifyOfflineSaveFailure(e);
          failureCount += 1;
          failureKinds.add(failureKind);
          _logger.warning(
            'Failed to mark file $fileID available offline',
            e,
            s,
          );
          await _cleanupFailedMark(file);
          if (_shouldStopBatchOnFailure(failureKind)) {
            failureCount += total - currentStep;
            break;
          }
        }
      }
    } finally {
      try {
        await dialog.hide();
      } catch (_) {}
    }

    _logger.info(
      'Mark offline completed: success=$successCount failure=$failureCount',
    );

    if (successCount > 0) {
      Bus.instance
          .fire(CollectionsUpdatedEvent('offline_availability_changed'));
    }

    if (!context.mounted) {
      return successCount > 0;
    }

    if (failureCount == 0) {
      showToast(
        context,
        context.l10n.filesAvailableOffline(successCount),
      );
    } else if (successCount > 0) {
      showToast(
        context,
        context.l10n.filesAvailableOfflinePartial(successCount, failureCount),
      );
    } else {
      showToast(
        context,
        _buildMarkFailureMessage(context, failureCount, failureKinds),
      );
    }

    return successCount > 0;
  }

  /// Clears offline state for the selected files on this device.
  Future<bool> unmarkFilesOffline(
    BuildContext context,
    Iterable<EnteFile> files,
  ) async {
    final eligibleFiles = getEligibleFiles(files);
    final sharedCount = countSharedFiles(files);
    _logger.info(
      'Remove offline requested for ${eligibleFiles.length} eligible files'
      '${sharedCount > 0 ? ' ($sharedCount shared skipped)' : ''}',
    );

    if (sharedCount > 0 && context.mounted) {
      showToast(
        context,
        context.l10n.actionNotSupportedForSharedFiles(sharedCount),
      );
    }

    if (eligibleFiles.isEmpty) {
      _logger.fine('No eligible files to remove from offline');
      return false;
    }

    final filesToUnmark = <EnteFile>[];
    for (final file in eligibleFiles) {
      final hasOfflineCopy = await getCurrentOfflineEncryptedCopy(file) != null;
      if (!LockerDB.instance.isFileMarkedOffline(file) && !hasOfflineCopy) {
        continue;
      }
      filesToUnmark.add(file);
    }

    final changedCount = filesToUnmark.length;
    _logger.fine('Removing offline state for $changedCount files');
    await unmarkFilesOfflineLocally(filesToUnmark);

    if (changedCount > 0) {
      Bus.instance
          .fire(CollectionsUpdatedEvent('offline_availability_changed'));
    }

    if (changedCount == 0 || !context.mounted) {
      return changedCount > 0;
    }

    showToast(
      context,
      context.l10n.filesRemovedFromOffline(changedCount),
    );
    return true;
  }

  Future<void> _setOfflineMarkForFile(
    EnteFile file,
    bool isMarkedOffline,
  ) async {
    final fileID = file.uploadedFileID!;
    await LockerDB.instance.setFilesMarkedOffline(
      [fileID],
      isMarkedOffline,
    );
  }

  /// Service-level unmark path used by non-UI flows like trash/delete.
  Future<void> unmarkFilesOfflineById(
    Iterable<int> fileIDs, {
    bool removeWorkingCopies = true,
  }) async {
    final ids = fileIDs.toSet();
    if (ids.isEmpty) {
      return;
    }

    _logger.fine(
      'Clearing offline state for ${ids.length} files'
      ' (removeWorkingCopies=$removeWorkingCopies)',
    );

    await LockerDB.instance.setFilesMarkedOffline(ids, false);
    await removeOfflineFileCopiesFromDisk(
      ids,
      removeWorkingCopies: removeWorkingCopies,
    );
  }

  Future<void> unmarkFilesOfflineLocally(
    Iterable<EnteFile> files, {
    bool removeWorkingCopies = true,
  }) async {
    final ids = <int>{};
    for (final file in files) {
      final fileID = file.uploadedFileID;
      if (fileID == null) {
        continue;
      }
      ids.add(fileID);
    }

    await unmarkFilesOfflineById(
      ids,
      removeWorkingCopies: removeWorkingCopies,
    );
  }

  /// Downloads first, then writes the local offline mark if the file is still
  /// active in the current library view.
  Future<bool> _ensureOfflineCopyAndMark(
    EnteFile file, {
    ProgressCallback? progressCallback,
  }) async {
    final fileID = file.uploadedFileID!;
    if (await getCurrentOfflineEncryptedCopy(file) == null) {
      await ensureEncryptedOfflineCopy(
        file,
        progressCallback: progressCallback,
      );
    }

    if (!await LockerDB.instance.hasActiveFile(fileID)) {
      _logger.warning(
        'Skipping offline mark for file $fileID because it is no longer active',
      );
      await unmarkFilesOfflineLocally(
        [file],
        removeWorkingCopies: false,
      );
      return false;
    }

    await _setOfflineMarkForFile(file, true);
    return true;
  }

  /// Keep decrypted working files intact; only clear offline state.
  Future<void> _cleanupFailedMark(EnteFile file) async {
    _logger.fine(
      'Cleaning up failed offline mark for file ${file.uploadedFileID}',
    );
    await unmarkFilesOfflineLocally(
      [file],
      removeWorkingCopies: false,
    );
  }

  String _buildMarkProgressMessage(
    BuildContext context,
    int current,
    int total, {
    int? percentage,
  }) {
    final progressLabel = percentage == null
        ? context.l10n.savingOffline
        : context.l10n.savingOfflineProgress(percentage);
    if (total == 1) {
      return progressLabel;
    }
    return '$progressLabel ($current/$total)';
  }

  _OfflineSaveFailureKind _classifyOfflineSaveFailure(Object error) {
    if (error is FileSystemException) {
      return _OfflineSaveFailureKind.storage;
    }
    if (_isNetworkError(error)) {
      return _OfflineSaveFailureKind.network;
    }
    return _OfflineSaveFailureKind.generic;
  }

  bool _shouldStopBatchOnFailure(_OfflineSaveFailureKind failureKind) {
    return failureKind == _OfflineSaveFailureKind.network ||
        failureKind == _OfflineSaveFailureKind.storage;
  }

  bool _isNetworkError(Object error) {
    if (error is SocketException) {
      return true;
    }
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError ||
          (error.type == DioExceptionType.unknown && error.response == null);
    }
    return false;
  }

  String _buildMarkFailureMessage(
    BuildContext context,
    int failureCount,
    Set<_OfflineSaveFailureKind> failureKinds,
  ) {
    final failureKind = failureKinds.length == 1
        ? failureKinds.first
        : _OfflineSaveFailureKind.generic;

    switch (failureKind) {
      case _OfflineSaveFailureKind.network:
        return context.l10n.failedToSaveFilesOfflineNetwork(failureCount);
      case _OfflineSaveFailureKind.storage:
        return context.l10n.failedToSaveFilesOfflineStorage(failureCount);
      case _OfflineSaveFailureKind.generic:
        return context.l10n.failedToSaveFilesOffline(failureCount);
    }
  }
}
