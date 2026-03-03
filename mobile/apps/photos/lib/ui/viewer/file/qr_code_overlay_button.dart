import "dart:io";

import "package:ente_qr/ente_qr.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/file/trash_file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/qr_code_content_sheet.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/file_util.dart";

class QrCodeOverlayButton extends StatefulWidget {
  final EnteFile file;
  final ValueListenable<bool> enableFullScreenNotifier;
  final bool isGuestView;

  const QrCodeOverlayButton({
    required this.file,
    required this.enableFullScreenNotifier,
    required this.isGuestView,
    super.key,
  });

  @override
  State<QrCodeOverlayButton> createState() => _QrCodeOverlayButtonState();
}

class _QrCodeOverlayButtonState extends State<QrCodeOverlayButton> {
  static final Map<String, _DetectionResult> _cache = {};
  final Logger _logger = Logger("QrCodeOverlayButton");
  final EnteQr _enteQr = EnteQr();

  bool _isEligible = false;
  bool _hasQr = false;
  bool _isChecking = false;
  String? _qrContent;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _evaluateFile();
  }

  @override
  void didUpdateWidget(covariant QrCodeOverlayButton oldWidget) {
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
        _hasQr = false;
        _qrContent = null;
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
        _hasQr = cachedResult.hasQr;
        _qrContent = cachedResult.content;
        _isChecking = false;
      });
      return;
    }

    setState(() {
      _isEligible = true;
      _hasQr = false;
      _qrContent = null;
      _isChecking = true;
    });

    try {
      final File? localFile = await getFile(widget.file);
      if (!mounted || requestId != _requestId) {
        return;
      }
      if (localFile == null || !localFile.existsSync()) {
        _cache[cacheKey] = const _DetectionResult(hasQr: false);
        setState(() {
          _hasQr = false;
          _qrContent = null;
          _isChecking = false;
        });
        return;
      }

      bool hasQr = false;
      String? qrContent;
      try {
        final result = await _enteQr.scanQrFromImage(localFile.path);
        if (result.success && result.content != null) {
          hasQr = true;
          qrContent = result.content;
        }
      } catch (error, stackTrace) {
        _logger.severe("Failed to scan QR code", error, stackTrace);
      }

      if (!mounted || requestId != _requestId) {
        return;
      }

      final _DetectionResult result = _DetectionResult(
        hasQr: hasQr,
        content: hasQr ? qrContent : null,
      );
      _cache[cacheKey] = result;
      setState(() {
        _hasQr = result.hasQr;
        _qrContent = result.content;
        _isChecking = false;
      });
    } catch (error, stackTrace) {
      _logger.severe("QR code detection failed", error, stackTrace);
      if (!mounted || requestId != _requestId) {
        return;
      }
      _cache[cacheKey] = const _DetectionResult(hasQr: false);
      setState(() {
        _hasQr = false;
        _qrContent = null;
        _isChecking = false;
      });
    }
  }

  bool _isFileEligible(EnteFile file) {
    return file.fileType == FileType.image ||
        file.fileType == FileType.livePhoto;
  }

  String _cacheKey(EnteFile file) {
    if (file.uploadedFileID != null) {
      return "qr_uploaded_${file.uploadedFileID}";
    }
    if (file.localID != null) {
      return "qr_local_${file.localID}";
    }
    return "qr_generated_${file.generatedID}";
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEligible || _isChecking || !_hasQr) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: widget.enableFullScreenNotifier,
      builder: (context, isFullScreen, _) {
        final bool shouldHide =
            isFullScreen || widget.isGuestView || widget.file is TrashFile;
        if (shouldHide) {
          return const SizedBox.shrink();
        }

        double bottomOffset = MediaQuery.paddingOf(context).bottom + 72.0;

        final caption = widget.file.caption;
        if (caption != null && caption.trim().isNotEmpty) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: caption.trim(),
              style: getEnteTextTheme(context).mini,
            ),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 3,
          );

          final double maxWidth = MediaQuery.sizeOf(context).width - 16.0;
          textPainter.layout(maxWidth: maxWidth);

          bottomOffset += textPainter.height + 24.0;
        }

        // Position above the text detection button
        bottomOffset += 44.0;

        return Positioned(
          bottom: bottomOffset,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: Colors.white.withAlpha(60),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: getEnteColorScheme(context).primary700,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).readQr,
                      style: getEnteTextTheme(context).mini.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onPressed() async {
    try {
      final String? content = _qrContent;
      if (content == null || content.isEmpty) {
        throw Exception("QR code content is empty");
      }
      if (!mounted) {
        return;
      }
      await showQrCodeContentSheet(context, content: content);
    } catch (error, stackTrace) {
      _logger.severe("Failed to show QR content", error, stackTrace);
      if (mounted) {
        await showGenericErrorDialog(context: context, error: error);
      }
    }
  }
}

class _DetectionResult {
  final bool hasQr;
  final String? content;

  const _DetectionResult({required this.hasQr, this.content});
}
