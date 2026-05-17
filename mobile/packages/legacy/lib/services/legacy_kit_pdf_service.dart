import "dart:convert";

import "package:ente_legacy/models/legacy_kit_models.dart";
import "package:flutter/services.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;

class LegacyKitPdfService {
  const LegacyKitPdfService();

  static const String _shareMetadataPrefix = "ente-legacy-kit-share-v1:";
  static const String _assetRoot = "packages/ente_legacy/assets";
  static const String _duckyAsset = "$_assetRoot/legacy_kit_sheet_ducky.png";
  static const String _heroBgLeftAsset =
      "$_assetRoot/legacy_kit_sheet_hero_bg_left.svg";
  static const String _heroBgRightAsset =
      "$_assetRoot/legacy_kit_sheet_hero_bg_right.svg";
  static const String _logoAsset = "$_assetRoot/legacy_kit_sheet_logo.svg";
  static const String _enteLogoBlackAsset =
      "$_assetRoot/legacy_kit_sheet_ente_logo_black.svg";
  static const String _enteComBadgeAsset =
      "$_assetRoot/legacy_kit_sheet_ente_com_badge.svg";
  static const String _personIconAsset =
      "$_assetRoot/legacy_kit_sheet_person_icon.svg";
  static const String _nunitoExtraBoldAsset =
      "$_assetRoot/fonts/Nunito-ExtraBold.ttf";
  static const String _nunitoBlackAsset = "$_assetRoot/fonts/Nunito-Black.ttf";
  static const String _interRegularAsset = "assets/fonts/Inter-Regular.ttf";
  static const String _interMediumAsset = "assets/fonts/Inter-Medium.ttf";
  static const String _interBoldAsset = "assets/fonts/Inter-Bold.ttf";

  static const PdfPageFormat _sheetPageFormat = PdfPageFormat(676, 900);
  static const PdfColor _background = PdfColor.fromInt(0xFFFAFAFA);
  static const PdfColor _green = PdfColor.fromInt(0xFF08C225);
  static const PdfColor _blue = PdfColor.fromInt(0xFF1071FF);
  static const PdfColor _heroBadge = PdfColor.fromInt(0xFF0A48A3);
  static const PdfColor _dark = PdfColor.fromInt(0xFF212121);
  static const PdfColor _black = PdfColor.fromInt(0xFF000000);
  static const PdfColor _white = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _muted = PdfColor.fromInt(0xFF969696);
  static const PdfColor _textLight = PdfColor.fromInt(0xFF999999);
  static const PdfColor _copyCodeBackground = PdfColor.fromInt(0xFF666666);
  static const PdfColor _chipBackground = PdfColor.fromInt(0xFF0A0A0A);
  static const List<PdfColor> _holderChipColors = [
    PdfColor.fromInt(0xFFFFA939),
    PdfColor.fromInt(0xFFF24822),
  ];

  Future<Uint8List> buildRecoverySheet({
    required String accountEmail,
    required String recoveryUrl,
    required LegacyKitShare share,
    required List<LegacyKitShare> allShares,
  }) async {
    final assets = await _loadAssets();
    final sortedShares = _sortedShares(allShares);
    final pdf = _document(
      keywords: _shareMetadata(share),
    );
    pdf.addPage(
      _buildPage(accountEmail, recoveryUrl, share, sortedShares, assets),
    );
    return pdf.save();
  }

  static String displayRecoveryUrl(String recoveryUrl) {
    final normalized = recoveryUrl.trim().replaceFirst(RegExp(r"/+$"), "");
    if (normalized.isEmpty) {
      return "legacy.ente.com";
    }
    return normalized.replaceFirst(RegExp(r"^https?://"), "");
  }

  Future<_SheetAssets> _loadAssets() async {
    final interRegular = await _loadFont(_interRegularAsset);
    final interMedium = await _loadFont(_interMediumAsset);
    final interBold = await _loadFont(_interBoldAsset);
    final nunitoExtraBold = await _loadFont(_nunitoExtraBoldAsset);
    final nunitoBlack = await _loadFont(_nunitoBlackAsset);
    final baseFont = interMedium ?? interRegular;

    return _SheetAssets(
      duckyImage: await _loadImage(_duckyAsset),
      heroBgLeftSvg: await _loadSvg(_heroBgLeftAsset),
      heroBgRightSvg: await _loadSvg(_heroBgRightAsset),
      logoSvg: await _loadSvg(_logoAsset),
      enteLogoBlackSvg: await _loadSvg(_enteLogoBlackAsset),
      enteComBadgeSvg: await _loadSvg(_enteComBadgeAsset),
      personIconSvg: await _loadSvg(_personIconAsset),
      nunitoExtraBold: nunitoExtraBold ?? nunitoBlack,
      nunitoBlack: nunitoBlack,
      theme: baseFont == null && interBold == null
          ? null
          : pw.ThemeData.withFont(
              base: baseFont,
              bold: interBold ?? baseFont,
            ),
    );
  }

  Future<String?> _loadSvg(String asset) async {
    try {
      return await rootBundle.loadString(asset);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _loadImage(String asset) async {
    try {
      final bytes = await rootBundle.load(asset);
      return bytes.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
    } catch (_) {
      return null;
    }
  }

  Future<pw.Font?> _loadFont(String asset) async {
    try {
      return pw.Font.ttf(await rootBundle.load(asset));
    } catch (_) {
      return null;
    }
  }

  pw.Document _document({required String keywords}) {
    return pw.Document(
      title: "Ente Legacy Kit",
      author: "ente",
      creator: "ente locker",
      subject: "Ente Legacy Kit recovery sheet",
      keywords: keywords,
      producer: "ente locker",
    );
  }

  String _shareMetadata(LegacyKitShare share) {
    return "$_shareMetadataPrefix${_encodeMetadataPayload(share.toQrPayload())}";
  }

  String _encodeMetadataPayload(String payload) {
    return base64Url.encode(utf8.encode(payload)).replaceAll("=", "");
  }

  pw.Page _buildPage(
    String accountEmail,
    String recoveryUrl,
    LegacyKitShare share,
    List<LegacyKitShare> sortedShares,
    _SheetAssets assets,
  ) {
    return pw.Page(
      pageFormat: _sheetPageFormat,
      margin: pw.EdgeInsets.zero,
      theme: assets.theme,
      build: (context) {
        final otherShares = sortedShares
            .where((item) => item.shareIndex != share.shareIndex)
            .toList(growable: false);
        return _buildSheet(
          accountEmail: accountEmail,
          recoveryUrl: recoveryUrl,
          share: share,
          otherShares: otherShares,
          assets: assets,
        );
      },
    );
  }

  pw.Widget _buildSheet({
    required String accountEmail,
    required String recoveryUrl,
    required LegacyKitShare share,
    required List<LegacyKitShare> otherShares,
    required _SheetAssets assets,
  }) {
    final qrPayload = share.toQrPayload();
    final copyCode = share.toCopyCode();
    return pw.SizedBox(
      width: _sheetPageFormat.width,
      height: _sheetPageFormat.height,
      child: pw.Container(
        color: _background,
        child: pw.Stack(
          fit: pw.StackFit.expand,
          children: [
            pw.Positioned(
              left: 42,
              top: 66,
              child: _header(assets),
            ),
            pw.Positioned(
              left: 550,
              top: 52,
              child: _enteLockup(assets),
            ),
            pw.Positioned(
              left: 456,
              top: 97,
              child: pw.Text(
                "Protect your digital life",
                style: pw.TextStyle(
                  color: _black,
                  fontSize: 15.7,
                  font: assets.nunitoExtraBold,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Positioned(
              left: 42,
              top: 162,
              child: _hero(accountEmail, share, assets),
            ),
            pw.Positioned(
              left: 66,
              top: 418,
              child: pw.Text(
                "How to recover the account?",
                style: pw.TextStyle(
                  color: _black,
                  fontSize: 20,
                  font: assets.nunitoExtraBold,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Positioned(
              left: 42,
              top: 453,
              child: _recoveryBlock(
                qrPayload,
                copyCode,
                otherShares,
                recoveryUrl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _enteLockup(_SheetAssets assets) {
    final enteLogoSvg = assets.enteLogoBlackSvg;
    final enteComBadgeSvg = assets.enteComBadgeSvg;
    return pw.SizedBox(
      width: 82,
      height: 38,
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 0,
            top: 0,
            child: enteLogoSvg == null
                ? pw.Text(
                    "ente",
                    style: pw.TextStyle(
                      color: _dark,
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  )
                : pw.SizedBox(
                    width: 75.7,
                    height: 22.5,
                    child: pw.SvgImage(svg: enteLogoSvg),
                  ),
          ),
          pw.Positioned(
            left: 44,
            top: 20,
            child: enteComBadgeSvg == null
                ? pw.Container(
                    width: 37,
                    height: 16,
                    decoration: const pw.BoxDecoration(
                      color: _green,
                      borderRadius:
                          pw.BorderRadius.all(pw.Radius.circular(999)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        ".com",
                        style: pw.TextStyle(
                          color: _dark,
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : pw.SizedBox(
                    width: 36.7,
                    height: 16.1,
                    child: pw.SvgImage(svg: enteComBadgeSvg),
                  ),
          ),
        ],
      ),
    );
  }

  pw.Widget _header(_SheetAssets assets) {
    final logoSvg = assets.logoSvg;
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        logoSvg == null
            ? _fallbackHeaderLogo()
            : pw.SizedBox(
                width: 29.4,
                height: 30.4,
                child: pw.SvgImage(svg: logoSvg),
              ),
        pw.SizedBox(width: 10),
        pw.Text(
          "Legacy Kit",
          style: pw.TextStyle(
            color: const PdfColor.fromInt(0xFF1C1C1C),
            fontSize: 20,
            font: assets.nunitoExtraBold,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _fallbackHeaderLogo() {
    return pw.Container(
      width: 29,
      height: 29,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _black, width: 1.6),
        shape: pw.BoxShape.circle,
      ),
      child: pw.Center(
        child: pw.Text(
          "e",
          style: pw.TextStyle(
            color: _black,
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _hero(
    String accountEmail,
    LegacyKitShare share,
    _SheetAssets assets,
  ) {
    return pw.ClipRRect(
      horizontalRadius: 24,
      verticalRadius: 24,
      child: pw.Container(
        width: 592,
        height: 218,
        color: _blue,
        child: pw.Stack(
          fit: pw.StackFit.expand,
          children: [
            if (assets.heroBgLeftSvg != null)
              pw.Positioned(
                left: 13,
                top: -24,
                child: pw.SizedBox(
                  width: 388,
                  height: 253,
                  child: pw.SvgImage(svg: assets.heroBgLeftSvg!),
                ),
              ),
            if (assets.heroBgRightSvg != null)
              pw.Positioned(
                left: 400.5,
                top: -6.5,
                child: pw.SizedBox(
                  width: 155,
                  height: 139,
                  child: pw.SvgImage(svg: assets.heroBgRightSvg!),
                ),
              ),
            pw.Positioned(
              left: 24,
              top: 24,
              child: _heroCopy(accountEmail, share, assets),
            ),
            if (assets.duckyImage != null)
              pw.Positioned(
                left: 398,
                top: 37,
                child: pw.Image(
                  pw.MemoryImage(assets.duckyImage!),
                  width: 158,
                  height: 152,
                  fit: pw.BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }

  pw.Widget _heroCopy(
    String accountEmail,
    LegacyKitShare share,
    _SheetAssets assets,
  ) {
    return pw.SizedBox(
      width: 344,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "HELD BY",
            style: const pw.TextStyle(
              color: _white,
              fontSize: 14,
              letterSpacing: 2.24,
            ),
          ),
          pw.SizedBox(height: 9),
          pw.Text(
            share.partName,
            style: pw.TextStyle(
              color: _white,
              fontSize: 32,
              font: assets.nunitoExtraBold,
              fontWeight: pw.FontWeight.bold,
              lineSpacing: 0,
            ),
          ),
          pw.SizedBox(height: 12),
          _legacyKitBadge(accountEmail, assets),
          pw.SizedBox(height: 12),
          pw.Text(
            "Store this somewhere safe",
            style: pw.TextStyle(
              color: _white,
              fontSize: 16,
              font: assets.nunitoBlack,
              fontWeight: pw.FontWeight.bold,
              lineSpacing: 3,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            "This is part of a legacy kit and can be used with any other part to\nget access to $accountEmail's Ente account",
            style: const pw.TextStyle(
              color: PdfColor(1, 1, 1, 0.86),
              fontSize: 11,
              lineSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _legacyKitBadge(String accountEmail, _SheetAssets assets) {
    return pw.SizedBox(
      width: 278,
      height: 32,
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                color: _heroBadge,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
            ),
          ),
          pw.Positioned(
            left: 15,
            top: 10,
            child: _legacyKitBadgeIcon(assets),
          ),
          pw.Positioned(
            left: 31,
            top: 8,
            child: pw.SizedBox(
              width: 237,
              height: 16,
              child: pw.Center(
                child: pw.FittedBox(
                  fit: pw.BoxFit.scaleDown,
                  child: pw.Text(
                    "Legacy Kit for $accountEmail",
                    maxLines: 1,
                    style: const pw.TextStyle(
                      color: _white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _legacyKitBadgeIcon(_SheetAssets assets) {
    final personIconSvg = assets.personIconSvg;
    if (personIconSvg != null) {
      return pw.SizedBox(
        width: 9,
        height: 11,
        child: pw.SvgImage(svg: personIconSvg),
      );
    }
    return pw.SizedBox(
      width: 9,
      height: 11,
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 2.2,
            top: 0,
            child: pw.Container(
              width: 4.6,
              height: 5.4,
              decoration: const pw.BoxDecoration(
                color: _white,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.Positioned(
            left: 0,
            top: 5.6,
            child: pw.Container(
              width: 9,
              height: 5.4,
              decoration: const pw.BoxDecoration(
                color: _white,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _recoveryBlock(
    String qrPayload,
    String copyCode,
    List<LegacyKitShare> otherShares,
    String recoveryUrl,
  ) {
    return pw.Container(
      width: 592,
      height: 406,
      padding: const pw.EdgeInsets.all(24),
      decoration: const pw.BoxDecoration(
        color: _dark,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(24)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 242,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 200,
                  height: 200,
                  padding: const pw.EdgeInsets.all(25),
                  decoration: const pw.BoxDecoration(
                    color: _white,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrPayload,
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.Container(
                  width: 242,
                  height: 126,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: _copyCodeBackground,
                    border: pw.Border.all(
                      color: _white,
                      width: 1,
                      style: pw.BorderStyle.dashed,
                    ),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Center(
                    child: _copyCodeText(copyCode),
                  ),
                ),
              ],
            ),
          ),
          pw.Spacer(),
          pw.SizedBox(
            width: 266,
            height: 358,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _instruction(
                  "1.",
                  "Get another part of the kit from",
                  extra: _holderChips(otherShares),
                ),
                pw.SizedBox(height: 31),
                _visitInstruction(recoveryUrl),
                pw.SizedBox(height: 31),
                _instruction("3.", "Upload both parts"),
                pw.SizedBox(height: 31),
                _instruction(
                  "4.",
                  "Change the password to gain\naccount access",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _instruction(
    String number,
    String text, {
    pw.Widget? extra,
  }) {
    return _instructionContent(
      number,
      pw.Text(
        text,
        style: const pw.TextStyle(
          color: _white,
          fontSize: 14,
          lineSpacing: 3,
        ),
      ),
      extra: extra,
    );
  }

  pw.Widget _copyCodeText(String copyCode) {
    return pw.SizedBox(
      width: 218,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: _displayCopyCodeLines(copyCode)
            .map(
              (line) => pw.SizedBox(
                height: 17,
                child: pw.FittedBox(
                  fit: pw.BoxFit.scaleDown,
                  child: pw.Text(
                    line,
                    textAlign: pw.TextAlign.center,
                    softWrap: false,
                    maxLines: 1,
                    style: pw.TextStyle(
                      color: _background,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  List<String> _displayCopyCodeLines(String copyCode) {
    const chunkSize = 33;
    final compactCode = copyCode.replaceAll(RegExp(r"\s+"), "");
    final chunks = <String>[];
    for (var index = 0; index < compactCode.length; index += chunkSize) {
      final nextIndex = index + chunkSize;
      final end =
          nextIndex > compactCode.length ? compactCode.length : nextIndex;
      chunks.add(compactCode.substring(index, end));
    }
    return chunks;
  }

  pw.Widget _visitInstruction(String recoveryUrl) {
    const textStyle = pw.TextStyle(
      color: _white,
      fontSize: 14,
      lineSpacing: 3,
    );
    return _instructionContent(
      "2.",
      pw.RichText(
        text: pw.TextSpan(
          style: textStyle,
          children: [
            const pw.TextSpan(text: "Visit "),
            pw.TextSpan(
              text: displayRecoveryUrl(recoveryUrl),
              style: const pw.TextStyle(
                color: _white,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _instructionContent(
    String number,
    pw.Widget content, {
    pw.Widget? extra,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 14,
          child: pw.Text(
            number,
            style: const pw.TextStyle(color: _muted, fontSize: 14),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              content,
              if (extra != null) ...[
                pw.SizedBox(height: 8),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8),
                  child: extra,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _holderChips(List<LegacyKitShare> shares) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: shares
          .asMap()
          .entries
          .map((entry) => _holderChip(entry.value, entry.key))
          .toList(growable: false),
    );
  }

  pw.Widget _holderChip(LegacyKitShare share, int chipIndex) {
    final initial = share.partName.trim().isEmpty
        ? "?"
        : share.partName.trim()[0].toUpperCase();
    final chipColor = _holderChipColors[chipIndex % _holderChipColors.length];
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: const pw.BoxDecoration(
        color: _chipBackground,
        // The PDF renderer does not clamp pill radii like Flutter does.
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 24,
            height: 24,
            decoration: pw.BoxDecoration(
              color: chipColor,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                initial,
                style: const pw.TextStyle(color: _white, fontSize: 12),
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            share.partName,
            style: const pw.TextStyle(color: _textLight, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<LegacyKitShare> _sortedShares(List<LegacyKitShare> shares) {
    return shares.toList(growable: false)
      ..sort((a, b) => a.shareIndex.compareTo(b.shareIndex));
  }
}

class _SheetAssets {
  final Uint8List? duckyImage;
  final String? heroBgLeftSvg;
  final String? heroBgRightSvg;
  final String? logoSvg;
  final String? enteLogoBlackSvg;
  final String? enteComBadgeSvg;
  final String? personIconSvg;
  final pw.Font? nunitoExtraBold;
  final pw.Font? nunitoBlack;
  final pw.ThemeData? theme;

  const _SheetAssets({
    required this.duckyImage,
    required this.heroBgLeftSvg,
    required this.heroBgRightSvg,
    required this.logoSvg,
    required this.enteLogoBlackSvg,
    required this.enteComBadgeSvg,
    required this.personIconSvg,
    required this.nunitoExtraBold,
    required this.nunitoBlack,
    required this.theme,
  });
}
