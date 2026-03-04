import "dart:io";

import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";

enum IOS26NativeUploadState {
  queued("queued"),
  inProgress("in_progress"),
  uploaded("uploaded"),
  failed("failed");

  final String wireName;
  const IOS26NativeUploadState(this.wireName);

  static IOS26NativeUploadState? fromWire(String? value) {
    if (value == null) {
      return null;
    }
    for (final state in IOS26NativeUploadState.values) {
      if (state.wireName == value) {
        return state;
      }
    }
    return null;
  }
}

class IOS26NativeUploadStatus {
  final String localID;
  final int collectionID;
  final int? generatedID;
  final int? uploadedFileID;
  final String? fileType;
  final IOS26NativeUploadState state;
  final String? errorMessage;
  final int updatedAt;

  const IOS26NativeUploadStatus({
    required this.localID,
    required this.collectionID,
    required this.generatedID,
    required this.uploadedFileID,
    required this.fileType,
    required this.state,
    required this.errorMessage,
    required this.updatedAt,
  });
}

class IOS26BackgroundUploadRouter {
  static const _channelName = "io.ente.photos/ios26_bg_upload";
  static const MethodChannel _channel = MethodChannel(_channelName);
  final _logger = Logger("IOS26BackgroundUploadRouter");

  IOS26BackgroundUploadRouter._privateConstructor();
  static final IOS26BackgroundUploadRouter instance =
      IOS26BackgroundUploadRouter._privateConstructor();

  bool get shouldUseNativePath {
    if (!Platform.isIOS) {
      return false;
    }
    if (!flagService.enableIos26NativeBgUpload) {
      return false;
    }
    return _iosMajorVersion() >= 26;
  }

  Future<bool> tryEnqueueCandidates(List<EnteFile> files) async {
    if (!shouldUseNativePath || files.isEmpty) {
      return false;
    }
    final isReady = await _isNativeUploaderReady();
    if (!isReady) {
      return false;
    }
    final payload = files
        .where((f) => f.localID != null && f.collectionID != null)
        .map(
          (f) => <String, dynamic>{
            "localID": f.localID,
            "collectionID": f.collectionID,
            "generatedID": f.generatedID,
            "fileType": f.fileType.name,
          },
        )
        .toList();
    if (payload.isEmpty) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>(
        "enqueueUploadCandidates",
        {"files": payload},
      );
      return result ?? false;
    } catch (e, s) {
      _logger.warning(
        "Native background enqueue failed, using legacy path",
        e,
        s,
      );
      return false;
    }
  }

  Future<bool> configureNativeUploader({
    required String baseURL,
    required String authToken,
    int? userID,
  }) async {
    if (!shouldUseNativePath) {
      return false;
    }
    if (baseURL.isEmpty || authToken.isEmpty) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>(
        "configureNativeUploader",
        {
          "baseURL": baseURL,
          "authToken": authToken,
          "userID": userID,
        },
      );
      return result ?? false;
    } catch (e, s) {
      _logger.warning("Failed to configure native uploader", e, s);
      return false;
    }
  }

  Future<bool> _isNativeUploaderReady() async {
    try {
      final result = await _channel.invokeMethod<bool>("isNativeUploaderReady");
      return result ?? false;
    } catch (e, s) {
      _logger.warning("Native uploader readiness check failed", e, s);
      return false;
    }
  }

  Future<List<IOS26NativeUploadStatus>> getUploadStates({
    int limit = 200,
  }) async {
    if (!shouldUseNativePath) {
      return const [];
    }
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        "getUploadStates",
        {"limit": limit},
      );
      if (result == null || result.isEmpty) {
        return const [];
      }
      final statuses = <IOS26NativeUploadStatus>[];
      for (final raw in result) {
        if (raw is! Map) {
          continue;
        }
        final map = Map<String, dynamic>.from(
          raw.map((key, value) => MapEntry(key.toString(), value)),
        );
        final localID = map["localID"] as String?;
        final collectionIDRaw = map["collectionID"];
        final stateRaw = map["state"] as String?;
        if (localID == null || localID.isEmpty || stateRaw == null) {
          continue;
        }
        final collectionID = _toInt(collectionIDRaw);
        if (collectionID == null) {
          continue;
        }
        final state = IOS26NativeUploadState.fromWire(stateRaw);
        if (state == null) {
          continue;
        }
        statuses.add(
          IOS26NativeUploadStatus(
            localID: localID,
            collectionID: collectionID,
            generatedID: _toInt(map["generatedID"]),
            uploadedFileID: _toInt(map["uploadedFileID"]),
            fileType: map["fileType"] as String?,
            state: state,
            errorMessage: map["errorMessage"] as String?,
            updatedAt: _toInt(map["updatedAt"]) ?? 0,
          ),
        );
      }
      return statuses;
    } catch (e, s) {
      _logger.warning("Failed to fetch native upload states", e, s);
      return const [];
    }
  }

  Future<bool> updateUploadState({
    required String localID,
    required int collectionID,
    required IOS26NativeUploadState state,
    String? errorMessage,
    int? uploadedFileID,
  }) async {
    if (!shouldUseNativePath) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>(
        "updateUploadState",
        {
          "localID": localID,
          "collectionID": collectionID,
          "state": state.wireName,
          "errorMessage": errorMessage,
          "uploadedFileID": uploadedFileID,
        },
      );
      return result ?? false;
    } catch (e, s) {
      _logger.warning("Failed to update native upload state", e, s);
      return false;
    }
  }

  Future<bool?> verifyDecryptedFileHash({
    required String filePath,
    required String expectedHash,
  }) async {
    if (!shouldUseNativePath || filePath.isEmpty || expectedHash.isEmpty) {
      return null;
    }
    try {
      return await _channel.invokeMethod<bool>(
        "verifyDecryptedFileHash",
        {
          "filePath": filePath,
          "expectedHash": expectedHash,
        },
      );
    } catch (e, s) {
      _logger.fine("Native hash verification unavailable, using fallback", e, s);
      return null;
    }
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  int _iosMajorVersion() {
    // Example: "Version 26.0 (Build ...)".
    final match = RegExp(
      r"Version\s+(\d+)",
    ).firstMatch(Platform.operatingSystemVersion);
    if (match == null) {
      return 0;
    }
    return int.tryParse(match.group(1) ?? "") ?? 0;
  }
}
