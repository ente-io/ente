import 'dart:async';
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import 'package:synchronized/synchronized.dart';

Future<PermissionState> requestPhotoMangerPermissions() {
  return PhotoManager.requestPermissionExtend(
    requestOption: const PermissionRequestOption(
      androidPermission: AndroidPermission(
        type: RequestType.common,
        mediaLocation: true,
      ),
    ),
  );
}

final _logger = Logger("PhotoManagerUtil");
// This is a wrapper for safe handling of PhotoManager.startChangeNotify() and
// PhotoManager.stopChangeNotify(). Since PhotoManager is globally shared, we want
// to make sure no notification is sent while it should not. The logic is that it will
// only start if no other asset (or task) requested to stop changes, or if the expiration
// time for the asset (task) expired. '_processingAssets' should be seen as a queue of
// open requests.
class PhotoManagerSafe {
  // Tracks processing assets with their expiration times
  static final Map<String?, DateTime> _processingAssets = {};

  // Timer for monitoring asset processing
  static Timer? _expirationTimer;

  // Synchronization lock
  static final _lock = Lock();

  // Estimate processing duration based on file size
  static Duration _estimateProcessingDuration(int fileSize) {
    final estimatedSeconds = (fileSize / (1024 * 1024)).ceil() * 2;
    return Duration(
      seconds: estimatedSeconds.clamp(5, 120),
    );
  }

  // Manage asset processing state. Lock ensures no start/stop is performed
  // at the same time.
  static Future<void> manageAssetProcessing({
    required String? assetId,
    required bool isStarting,
    int? fileSize,
  }) async {
    await _lock.synchronized(() async {
      try {
        if (isStarting) {
          // Remove the asset from processing only if assetId is not null
          if (assetId != null) {
            _processingAssets.remove(assetId);
          }

          // Restart change notify only if no assets are processing and no stop was requested
          if (_processingAssets.isEmpty) {
            await PhotoManager.startChangeNotify();
          }

          _stopExpirationMonitoringIfEmpty();
        } else {
          // Stopping the asset
          final duration = _estimateProcessingDuration(
            fileSize ?? 10 * 1024 * 1024, // 10MB default
          );

          // First asset to request stop
          if (_processingAssets.isEmpty) {
            await PhotoManager.stopChangeNotify();
          }

          // Track the processing asset with expiration
          _processingAssets[assetId] = DateTime.now().add(duration);

          _startOrContinueExpirationMonitoring();
        }
      } catch (e, stackTrace) {
        _logger.severe(
          "${isStarting ? 'Start' : 'Stop'}ChangeNotify error for ID $assetId", 
          e, 
          stackTrace,
        );
        rethrow;
      }
    });
  }

  // Start or continue the expiration monitoring timer
  static void _startOrContinueExpirationMonitoring() {
    if (_expirationTimer != null && _expirationTimer!.isActive) return;

      _expirationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        
        // Remove expired assets
        _processingAssets.removeWhere((assetId, expiresAt) {
          final bool isExpired = expiresAt.isBefore(now);
          if (isExpired) {
          }
          return isExpired;
        });

        // Handle asset processing completion
        if (_processingAssets.isEmpty) {
          
          // Start ChangeNotify
          try {
            PhotoManager.startChangeNotify();
          } catch (e, stackTrace) {
            _logger.severe("Error restarting change notify", e, stackTrace);
          }

          _stopExpirationMonitoringIfEmpty();
        }
    });
  }

  // Stop the expiration monitoring timer if no assets are being processed
  static void _stopExpirationMonitoringIfEmpty() {
    if (_processingAssets.isEmpty) {
      _expirationTimer?.cancel();
      _expirationTimer = null;
    }
  }

  static Future<void> stopChangeNotify(String? assetId, {int? fileSize}) =>
    manageAssetProcessing(
      assetId: assetId, 
      isStarting: false, 
      fileSize: fileSize,
    );

  static Future<void> startChangeNotify(String? assetId) =>
    manageAssetProcessing(
      assetId: assetId, 
      isStarting: true,
    );
}