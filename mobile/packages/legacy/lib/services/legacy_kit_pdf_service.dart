import "dart:convert";
import "dart:typed_data";

import "package:ente_legacy/models/legacy_kit_models.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;

class LegacyKitPdfService {
  const LegacyKitPdfService();

  static const String _shareMetadataPrefix = "ente-legacy-kit-share-v1:";

  static const PdfPageFormat _sheetPageFormat = PdfPageFormat(676, 900);
  static const PdfColor _background = PdfColor.fromInt(0xFFFAFAFA);
  static const PdfColor _green = PdfColor.fromInt(0xFF08C225);
  static const PdfColor _dark = PdfColor.fromInt(0xFF212121);
  static const PdfColor _black = PdfColor.fromInt(0xFF000000);
  static const PdfColor _white = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _muted = PdfColor.fromInt(0xFF969696);
  static const PdfColor _lightText = PdfColor.fromInt(0xFFE5E5E5);

  Future<Uint8List> buildRecoverySheet({
    required String accountEmail,
    required LegacyKitShare share,
    required List<LegacyKitShare> allShares,
  }) async {
    final sortedShares = _sortedShares(allShares);
    final pdf = _document(
      keywords: _shareMetadata(share),
    );
    pdf.addPage(_buildPage(accountEmail, share, sortedShares));
    return pdf.save();
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
    LegacyKitShare share,
    List<LegacyKitShare> sortedShares,
  ) {
    return pw.Page(
      pageFormat: _sheetPageFormat,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        final otherShares = sortedShares
            .where((item) => item.shareIndex != share.shareIndex)
            .toList(growable: false);
        return _buildSheet(
          accountEmail: accountEmail,
          share: share,
          otherShares: otherShares,
        );
      },
    );
  }

  pw.Widget _buildSheet({
    required String accountEmail,
    required LegacyKitShare share,
    required List<LegacyKitShare> otherShares,
  }) {
    final qrPayload = share.toQrPayload();
    final copyCode = share.toCopyCode();
    return pw.Container(
      color: _background,
      padding: const pw.EdgeInsets.fromLTRB(42, 40, 42, 40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header(),
          pw.SizedBox(height: 29),
          _hero(accountEmail, share),
          pw.SizedBox(height: 32),
          pw.Text(
            "How to recover the account?",
            style: pw.TextStyle(
              color: _black,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _recoveryBlock(qrPayload, copyCode, otherShares),
          pw.Spacer(),
          pw.Center(
            child: pw.Text(
              "Store this sheet somewhere safe.\nOn its own, this sheet cannot unlock the account.",
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                color: _muted,
                fontSize: 12,
                lineSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _header() {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
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
        ),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "ente",
              style: pw.TextStyle(
                color: _green,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              "Legacy Kit",
              style: const pw.TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _hero(String accountEmail, LegacyKitShare share) {
    return pw.Container(
      width: 592,
      height: 213,
      padding: const pw.EdgeInsets.all(24),
      decoration: const pw.BoxDecoration(
        color: _green,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(24)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 344,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  "HELD BY",
                  style: const pw.TextStyle(
                    color: _white,
                    fontSize: 14,
                    letterSpacing: 2.2,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  share.partName,
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: PdfColor(0, 0, 0, 0.36),
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Text(
                    "Legacy Kit for $accountEmail",
                    style: const pw.TextStyle(color: _white, fontSize: 14),
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  "This sheet is one part of a recovery key. If $accountEmail loses access, this and any one other can recover their account.",
                  style: const pw.TextStyle(
                    color: PdfColor(1, 1, 1, 0.86),
                    fontSize: 12,
                    lineSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Container(
            width: 146,
            height: 146,
            decoration: const pw.BoxDecoration(
              color: _white,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(18)),
            ),
            child: pw.Center(
              child: pw.Text(
                "QR",
                style: pw.TextStyle(
                  color: _green,
                  fontSize: 42,
                  fontWeight: pw.FontWeight.bold,
                ),
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
  ) {
    return pw.Container(
      width: 592,
      height: 378,
      padding: const pw.EdgeInsets.all(24),
      decoration: const pw.BoxDecoration(
        color: _dark,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(24)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 201,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 200,
                  height: 200,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: const pw.BoxDecoration(
                    color: _white,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrPayload,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  "OR",
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "copy code text",
                  style: const pw.TextStyle(color: _lightText, fontSize: 12),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: 201,
                  height: 75,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _green,
                    border: pw.Border.all(
                      color: _white,
                      width: 1,
                      style: pw.BorderStyle.dashed,
                    ),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      copyCode,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: _background,
                        fontSize: copyCode.length > 220 ? 5.5 : 6.5,
                        fontWeight: pw.FontWeight.bold,
                        lineSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 28),
          pw.SizedBox(
            width: 291,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _instruction(
                  "1.",
                  "Get one other sheet. The other holders are:",
                  extra: _holderChips(otherShares),
                ),
                _instruction(
                  "2.",
                  "Go to legacy.ente.com and click Start recovery",
                ),
                _instruction("3.", "Scan the QR codes from both sheets"),
                _instruction(
                  "4.",
                  "Wait through the recovery period (if one is set).",
                ),
                _instruction(
                  "5.",
                  "Return to the site to get the recovery key",
                  bottomPadding: 0,
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
    double bottomPadding = 16,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: bottomPadding),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 20,
            child: pw.Text(
              number,
              style: const pw.TextStyle(color: _muted, fontSize: 14),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  text,
                  style: const pw.TextStyle(
                    color: _white,
                    fontSize: 14,
                    lineSpacing: 3,
                  ),
                ),
                if (extra != null) ...[
                  pw.SizedBox(height: 8),
                  extra,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _holderChips(List<LegacyKitShare> shares) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: shares.map(_holderChip).toList(growable: false),
    );
  }

  pw.Widget _holderChip(LegacyKitShare share) {
    final initial = share.partName.trim().isEmpty
        ? "?"
        : share.partName.trim()[0].toUpperCase();
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF0A0A0A),
        // The PDF renderer does not clamp pill radii like Flutter does.
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 24,
            height: 24,
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFA939),
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
            style: const pw.TextStyle(color: _muted, fontSize: 12),
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
