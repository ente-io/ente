import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:logging/logging.dart";
import "package:mobile_ocr/mobile_ocr.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/file/trash_file.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/viewer/file/text_detection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/navigation_util.dart";

class TextDetectionOverlayButton extends StatefulWidget {
  final EnteFile file;
  final ValueListenable<bool> enableFullScreenNotifier;
  final bool isGuestView;
  final bool showOnlyInfoButton;
  final int? userID;

  const TextDetectionOverlayButton({
    required this.file,
    required this.enableFullScreenNotifier,
    required this.isGuestView,
    required this.showOnlyInfoButton,
    required this.userID,
    super.key,
  });

  @override
  State<TextDetectionOverlayButton> createState() =>
      _TextDetectionOverlayButtonState();
}

class _TextDetectionOverlayButtonState
    extends State<TextDetectionOverlayButton> {
  static const double _buttonSize = 32.0;
  static const double _barSlotExtent = 48.0;
  static final Map<String, _DetectionResult> _cache = {};
  final Logger _logger = Logger("TextDetectionOverlayButton");
  final MobileOcr _mobileOcr = MobileOcr();

  bool _isEligible = false;
  bool _hasText = false;
  bool _isChecking = false;
  String? _localFilePath;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _evaluateFile();
  }

  @override
  void didUpdateWidget(covariant TextDetectionOverlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_didFileChange(oldWidget.file, widget.file)) {
      _evaluateFile();
    }
  }

  bool _didFileChange(EnteFile oldFile, EnteFile newFile) {
    if (oldFile.generatedID != newFile.generatedID) {
      return true;
    }
    if (oldFile.uploadedFileID != newFile.uploadedFileID) {
      return true;
    }
    if (oldFile.localID != newFile.localID) {
      return true;
    }
    return false;
  }

  Future<void> _evaluateFile() async {
    final bool isEligible = _isFileEligible(widget.file);
    final int requestId = ++_requestId;

    if (!isEligible) {
      setState(() {
        _isEligible = false;
        _hasText = false;
        _localFilePath = null;
        _isChecking = false;
      });
      return;
    }

    final String cacheKey = _cacheKey(widget.file);
    final _DetectionResult? cachedResult = _cache[cacheKey];
    if (cachedResult != null) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _isEligible = true;
        _hasText = cachedResult.hasText;
        _localFilePath = cachedResult.localPath;
        _isChecking = false;
      });
      return;
    }

    setState(() {
      _isEligible = true;
      _hasText = false;
      _localFilePath = null;
      _isChecking = true;
    });

    try {
      final File? localFile = await getFile(widget.file);
      if (!mounted || requestId != _requestId) {
        return;
      }
      if (localFile == null || !localFile.existsSync()) {
        _cache[cacheKey] = const _DetectionResult(hasText: false);
        setState(() {
          _hasText = false;
          _localFilePath = null;
          _isChecking = false;
        });
        return;
      }

      bool hasText = false;
      try {
        hasText = await _mobileOcr.hasText(imagePath: localFile.path);
      } catch (error, stackTrace) {
        _logger.severe("Failed to run hasText", error, stackTrace);
      }

      if (!mounted || requestId != _requestId) {
        return;
      }

      final _DetectionResult result = _DetectionResult(
        hasText: hasText,
        localPath: hasText ? localFile.path : null,
      );
      _cache[cacheKey] = result;
      setState(() {
        _hasText = result.hasText;
        _localFilePath = result.localPath;
        _isChecking = false;
      });
    } catch (error, stackTrace) {
      _logger.severe("Text detection pre-check failed", error, stackTrace);
      if (!mounted || requestId != _requestId) {
        return;
      }
      _cache[cacheKey] = const _DetectionResult(hasText: false);
      setState(() {
        _hasText = false;
        _localFilePath = null;
        _isChecking = false;
      });
    }
  }

  bool _isFileEligible(EnteFile file) {
    if (!flagService.textDetection) {
      return false;
    }
    return file.fileType == FileType.image ||
        file.fileType == FileType.livePhoto;
  }

  String _cacheKey(EnteFile file) {
    if (file.uploadedFileID != null) {
      return "uploaded_${file.uploadedFileID}";
    }
    if (file.localID != null) {
      return "local_${file.localID}";
    }
    return "generated_${file.generatedID}";
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEligible || _isChecking || !_hasText) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: widget.enableFullScreenNotifier,
      builder: (context, isFullScreen, _) {
        final bool shouldHide = isFullScreen || widget.isGuestView;
        if (shouldHide) {
          return const SizedBox.shrink();
        }
        if (!_hasShareSlot()) {
          return const SizedBox.shrink();
        }
        final double bottomOffset = MediaQuery.paddingOf(context).bottom + 96.0;
        final int slotCount = _bottomBarSlotCount();
        if (slotCount <= 0) {
          return const SizedBox.shrink();
        }
        final List<Widget> rowChildren = List<Widget>.generate(
          slotCount,
          (int index) => _buildPlaceholderSlot(
            context: context,
            isShareSlot: index == slotCount - 1,
          ),
        );
        return Positioned(
          bottom: bottomOffset,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rowChildren,
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderSlot({
    required BuildContext context,
    required bool isShareSlot,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: _barSlotExtent,
        height: _barSlotExtent,
        child: isShareSlot
            ? Center(child: _buildButton(context))
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    const String detectTextLabel = "Detect Text";
    return Tooltip(
      message: detectTextLabel,
      child: IconButton(
        tooltip: detectTextLabel,
        constraints: const BoxConstraints.tightFor(
          width: _buttonSize,
          height: _buttonSize,
        ),
        padding: EdgeInsets.zero,
        onPressed: _onPressed,
        icon: SvgPicture.asset(
          "assets/detect_text.svg",
          width: _buttonSize,
          height: _buttonSize,
          semanticsLabel: detectTextLabel,
        ),
      ),
    );
  }

  Future<void> _onPressed() async {
    try {
      final String? path = _localFilePath ?? await _ensureLocalFilePath();
      if (path == null) {
        throw Exception("Failed to resolve file path for text detection");
      }
      if (!mounted) {
        return;
      }
      await routeToPage(
        context,
        TextDetectionPage(imagePath: path),
      );
    } catch (error, stackTrace) {
      _logger.severe("Failed to start text detection", error, stackTrace);
      if (mounted) {
        await showGenericErrorDialog(context: context, error: error);
      }
    }
  }

  Future<String?> _ensureLocalFilePath() async {
    final File? localFile = await getFile(widget.file);
    if (localFile == null || !localFile.existsSync()) {
      return null;
    }
    return localFile.path;
  }

  bool _hasShareSlot() {
    if (widget.showOnlyInfoButton) {
      return false;
    }
    if (widget.file is TrashFile) {
      return false;
    }
    return true;
  }

  int _bottomBarSlotCount() {
    if (!_hasShareSlot()) {
      return 0;
    }
    int count = 1; // Info button
    if (_supportsEdit(widget.file)) {
      count++;
    }
    if (_isOwnedByUser()) {
      count++;
    }
    return count + 1; // Share slot
  }

  bool _isOwnedByUser() {
    final int? ownerID = widget.file.ownerID;
    if (ownerID == null) {
      return true;
    }
    final int? userID = widget.userID;
    if (userID == null) {
      return false;
    }
    return ownerID == userID;
  }

  bool _supportsEdit(EnteFile file) {
    return file.fileType == FileType.image ||
        file.fileType == FileType.livePhoto ||
        file.fileType == FileType.video;
  }
}

class _DetectionResult {
  final bool hasText;
  final String? localPath;

  const _DetectionResult({required this.hasText, this.localPath});
}
