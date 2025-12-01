import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ente_ui/theme/colors.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

/// QR box background color - light gray for good contrast
const Color qrBoxColor = Color.fromRGBO(245, 245, 247, 1);

/// QR text color - always black for scanability
const Color qrTextColor = textBaseLight;

/// Configuration for the branding shown at bottom right of QR code
sealed class QrBranding {
  const QrBranding();
}

/// Text-based branding (e.g., "ente")
class QrTextBranding extends QrBranding {
  final String text;
  final String fontFamily;

  const QrTextBranding({
    required this.text,
    this.fontFamily = 'Montserrat',
  });
}

/// SVG-based branding (e.g., Auth logo)
class QrSvgBranding extends QrBranding {
  final String assetPath;
  final double height;

  const QrSvgBranding({
    required this.assetPath,
    this.height = 12,
  });
}

/// A customizable QR code dialog widget that can be used across Ente apps.
///
/// Example usage for Auth app:
/// ```dart
/// QrCodeDialog(
///   data: code.rawData,
///   title: code.account,
///   subtitle: code.issuer,
///   accentColor: authAccentColor,
///   branding: QrSvgBranding(assetPath: 'assets/svg/auth-logo.svg'),
///   shareFileName: 'ente_auth_qr_${code.account}.png',
///   shareText: 'QR code for ${code.account}',
/// )
/// ```
///
/// Example usage for Photos app:
/// ```dart
/// QrCodeDialog(
///   data: publicUrl,
///   title: albumName,
///   accentColor: enteColorScheme.primary500,
///   branding: QrTextBranding(text: 'ente'),
///   shareFileName: 'ente_qr_$albumName.png',
///   shareText: 'Scan this QR code to view my $albumName album',
///   errorCorrectionLevel: QrErrorCorrectLevel.M,
/// )
/// ```
class QrCodeDialog extends StatefulWidget {
  /// The data to encode in the QR code
  final String data;

  /// Primary title shown above the QR code
  final String title;

  /// Optional subtitle shown below the title
  final String? subtitle;

  /// Accent color used for finder pattern and branding
  final Color accentColor;

  /// Optional branding widget shown at bottom right
  final QrBranding? branding;

  /// File name for the shared QR code image
  final String shareFileName;

  /// Text to accompany the shared QR code
  final String shareText;

  /// Error correction level for the QR code
  final int errorCorrectionLevel;

  /// Dialog title text (defaults to "QR Code")
  final String dialogTitle;

  /// Share button text (defaults to "Share")
  final String shareButtonText;

  /// Center logo image asset path (optional)
  final String? logoAssetPath;

  /// Optionally override the default PrettyQrDecoration
  final PrettyQrDecoration? decoration;

  /// Background color for the QR card
  final Color? qrBackgroundColor;

  const QrCodeDialog({
    super.key,
    required this.data,
    required this.title,
    this.subtitle,
    required this.accentColor,
    this.branding,
    required this.shareFileName,
    required this.shareText,
    this.errorCorrectionLevel = QrErrorCorrectLevel.L,
    this.dialogTitle = 'QR Code',
    this.shareButtonText = 'Share',
    this.logoAssetPath,
    this.decoration,
    this.qrBackgroundColor,
  });

  @override
  State<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<QrCodeDialog> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _shareQrCode() async {
    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/${widget.shareFileName}');
        await file.writeAsBytes(pngBytes);

        // Get the render box for share position (required for iPad)
        final box = context.findRenderObject() as RenderBox?;
        final sharePositionOrigin =
            box != null ? box.localToGlobal(Offset.zero) & box.size : null;

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: widget.shareText,
            sharePositionOrigin: sharePositionOrigin,
          ),
        );

        // Close the dialog after sharing is initiated
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double qrSize = min(screenWidth - 80, 300.0);
    final double qrCodeSize =
        max(qrSize - 100, 150.0); // Ensure minimum size of 150
    final double qrCodeSizeEven = (qrCodeSize / 2).round() * 2.0;
    final enteTextTheme = getEnteTextTheme(context);
    final enteColorScheme = getEnteColorScheme(context);

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBackgroundColor = widget.qrBackgroundColor ?? qrBoxColor;
    final qrDecoration =
        widget.decoration ?? _buildDefaultDecoration(widget.logoAssetPath);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: enteColorScheme.backgroundBase,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.dialogTitle,
                    style: enteTextTheme.largeBold.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? enteColorScheme.backgroundElevated2
                            : qrBoxColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.close,
                        color:
                            isDarkMode ? enteColorScheme.textBase : qrTextColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // QR Code with RepaintBoundary for sharing
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title at top center (inside border)
                        SizedBox(
                          width: 225,
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: enteTextTheme.largeBold.copyWith(
                              color: qrTextColor,
                              letterSpacing: -0.76,
                            ),
                          ),
                        ),
                        if (widget.subtitle != null &&
                            widget.subtitle!.isNotEmpty) ...[
                          SizedBox(
                            width: 175,
                            child: Text(
                              widget.subtitle!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: enteTextTheme.miniBold.copyWith(
                                color: qrTextColor.withValues(alpha: 0.6),
                                letterSpacing: -0.48,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // QR Code with pretty styling
                        SizedBox(
                          width: qrCodeSize,
                          height: qrCodeSize,
                          child: PrettyQrView(
                            qrImage: QrImage(
                              QrCode.fromData(
                                data: widget.data,
                                errorCorrectLevel: widget.errorCorrectionLevel,
                              ),
                            ),
                            decoration: qrDecoration,
                          ),
                        ),
                        const SizedBox(height: 42),
                      ],
                    ),

                    // Branding at bottom right (inside border)
                    if (widget.branding != null)
                      Positioned(
                        bottom: 0,
                        right: 2,
                        child: _buildBranding(widget.branding!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Share button
            GestureDetector(
              onTap: _shareQrCode,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.shareButtonText,
                  textAlign: TextAlign.center,
                  style: enteTextTheme.bodyBold.copyWith(
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranding(QrBranding branding) {
    return switch (branding) {
      QrTextBranding(:final text, :final fontFamily) => Text(
          text,
          style: TextStyle(
            color: widget.accentColor,
            fontSize: 16,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
      QrSvgBranding(:final assetPath, :final height) => SvgPicture.asset(
          assetPath,
          height: height,
          colorFilter: ColorFilter.mode(
            widget.accentColor,
            BlendMode.srcIn,
          ),
        ),
    };
  }

  PrettyQrDecoration _buildDefaultDecoration(String? logoAssetPath) {
    return PrettyQrDecoration(
      shape: PrettyQrShape.custom(
        const PrettyQrDotsSymbol(
          color: qrTextColor,
          unifiedFinderPattern: false,
          unifiedAlignmentPatterns: false,
        ),
        finderPattern: PrettyQrSquaresSymbol(
          color: qrTextColor,
          rounding: 0.5,
          unifiedFinderPattern: true,
          finderPatternOuterThickness: 1.4,
          finderPatternOuterColor: widget.accentColor,
          finderPatternInnerDotSize: 0.8,
          finderPatternInnerRounding: 1.0,
        ),
        alignmentPatterns: const PrettyQrSquaresSymbol(
          color: qrTextColor,
          rounding: 1.0,
        ),
      ),
      image: logoAssetPath != null
          ? PrettyQrDecorationImage(
              image: AssetImage(logoAssetPath),
              scale: 0.25,
              padding: const EdgeInsets.all(24),
              position: PrettyQrDecorationImagePosition.embedded,
            )
          : null,
      background: Colors.transparent,
      quietZone: PrettyQrQuietZone.zero,
    );
  }
}
