import 'dart:convert';
import 'dart:ui' as ui;

import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<String> generateQRImageBase64(String data) async {
  final qrPainter = QrPainter(
    data: data,
    version: QrVersions.auto,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Colors.black,
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Colors.black,
    ),
  );

  const size = 250.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  qrPainter.paint(canvas, const Size(size, size));
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  return base64Encode(pngBytes);
}

Future<String> generateOTPEntryHtml(
  Code code,
  BuildContext context,
) async {
  final qrBase64 = await generateQRImageBase64(code.rawData);
  String notes = code.display.note;
  if (notes.isNotEmpty) {
    notes = '<p>Note: <b>$notes</b></p>';
  }
  return '''
    <div class="otp-entry">
      <div>
        <p><b>${code.issuer}</b> </p>
        <p><b>${code.account}</b></p>
        <br />
        <p>Type: <b>${code.type.name}</b></p>
        <p>Algorithm: <b>${code.algorithm.name}</b></p>
        <p>Digits: <b>${code.digits}</b></p>
        <p>Recovery Code: <b>${code.secret}</b></p>
        $notes
      </div>
        <img src="data:image/png;base64,$qrBase64" alt="QR Code">
    </div>
    <br/>
    <hr class="red-separator" />
    <br/>
  ''';
}

Future<String> generateHtml(BuildContext context) async {
  DateTime now = DateTime.now().toUtc();
  String formattedDate = DateFormat('d MMMM, yyyy').format(now);
  final allCodes = await CodeStore.instance.getAllCodes();
  final List<String> enteries = [];

  for (final code in allCodes) {
    if (code.hasError) continue;
    final entry = await generateOTPEntryHtml(code, context);
    enteries.add(entry);
  }

  return '''
  <!DOCTYPE html>
  <html>
  <meta content="text/html; charset=utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1" />
  <style>
    body {
      background-color: #f0f1f3;
      font-family: "Helvetica Neue", "Segoe UI", Helvetica, sans-serif;
      font-size: 16px;
      line-height: 27px;
      margin: 0;
      color: #444;
    }

    pre {
      background: #f4f4f4f4;
      padding: 2px;
    }

    table {
      width: 100%;
      border: 1px solid #ddd;
    }

    table td {
      border-color: #ddd;
      padding: 5px;
    }

    .wrap {
      background-color: #fff;
      padding: 30px;
      max-width: 600px;
      margin: 0 auto;
      border-radius: 5px;
    }

    .button {
      background: #0055d4;
      border-radius: 3px;
      text-decoration: none !important;
      color: #fff !important;
      font-weight: bold;
      padding: 10px 30px;
      display: inline-block;
    }

    .button:hover {
      background: #111;
    }

    .footer {
      text-align: center;
      font-size: 12px;
      color: #888;
    }

    .footer a {
      color: #888;
      margin-right: 5px;
    }

    .gutter {
      padding: 30px;
    }

    img {
      max-width: 100%;
      height: auto;
    }

    a {
      color: #0055d4;
    }

    a:hover {
      color: #111;
    }

    @media screen and (max-width: 700px) {
      .wrap {
        max-width: auto;
      }

      .gutter {
        padding: 10px;
      }
    }

    .footer-icons {
      padding: 4px !important;
      width: 24px !important;
    }

    .otp-entry {
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .otp-entry div {
      flex: 1;
    }

    .otp-entry p {
      margin: 2px 0;
    }

    hr.red-separator {
      border: none;
      height: 1px;
      background-color: rgb(173, 0, 255);
    }

  </style>
  </head>
  <body>
    <h1 style="text-align: center;">Ente Auth</h1>
    <h4 style="text-align: center; margin-bottom: 5px;">OTP Data Export</h4>
    <p style="text-align: center; margin-top: 0px;">$formattedDate</p>
    <div class="gutter" style="padding: 4px">&nbsp;</div>
    <div class="wrap" style=" background-color: rgb(255, 255, 255); padding: 2px
            30px 30px 30px; max-width: 700px; margin: 0 auto; border-radius: 5px;
            font-size: 16px; ">
      <main>
        <p>
          ${enteries.join('')}
        </p>
      </main>
    </div>
    <br />  
  
  <div class="footer" style="text-align: center; font-size: 12px; color:
    rgb(136, 136, 136)">
    <div>
      <a href="https://ente.io" target="_blank"><img src="https://email-assets.ente.io/ente-green.png" style="width: 100px;
        padding: 24px" title="Ente" alt="Ente" /></a>
    </div>
    <div>
      <a href="https://fosstodon.org/@ente" target="_blank"><img src="https://email-assets.ente.io/mastodon-icon.png"
          class="footer-icons" style="width: 24px; padding: 4px" title="Mastodon" alt="Mastodon" /></a>
      <a href="https://twitter.com/enteio" target="_blank"><img src="https://email-assets.ente.io/twitter-icon.png"
          class="footer-icons" style="width: 24px; padding: 4px" title="Twitter" alt="Twitter" /></a>
      <a href="https://discord.ente.io" target="_blank"><img src="https://email-assets.ente.io/discord-icon.png"
          class="footer-icons" style="width: 24px; padding: 4px" title="Discord" alt="Discord" /></a>
      <a href="https://github.com/ente-io" target="_blank"><img src="https://email-assets.ente.io/github-icon.png"
          class="footer-icons" style="width: 24px; padding: 4px" title="GitHub" alt="GitHub" /></a>
    </div>
    <p>
      Ente Technologies, Inc.
      <br /> 1111B S Governors Ave 6032 Dover, DE 19904
    </p>
    <br />
  </div>
  </body>
  
  </html>
  ''';
}
