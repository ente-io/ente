import 'dart:io';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/network.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppUpdateDialog extends StatefulWidget {
  final LatestVersionInfo? latestVersionInfo;

  const AppUpdateDialog(this.latestVersionInfo, {Key? key}) : super(key: key);

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  @override
  Widget build(BuildContext context) {
    final enteTextTheme = getEnteTextTheme(context);
    final List<Widget> changelog = [];
    for (final log in widget.latestVersionInfo!.changelog) {
      changelog.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
          child: Text(
            "- " + log,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 14,
                ),
          ),
        ),
      );
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.latestVersionInfo!.name!,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Padding(padding: EdgeInsets.all(8)),
        if (changelog.isNotEmpty)
          const Text(
            "Changelog",
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        if (changelog.isNotEmpty) const Padding(padding: EdgeInsets.all(4)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: changelog,
        ),
        const Padding(padding: EdgeInsets.all(8)),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: OutlinedButton(
            style: Theme.of(context).outlinedButtonTheme.style!.copyWith(
              textStyle: MaterialStateProperty.resolveWith<TextStyle?>(
                (Set<MaterialState> states) {
                  return Theme.of(context).textTheme.titleMedium;
                },
              ),
            ),
            onPressed: () => launchUrlString(
              widget.latestVersionInfo!.url!,
              mode: LaunchMode.externalApplication,
            ),
            child: Text(
              context.l10n.downloadUpdate,
            ),
          ),
        ),
      ],
    );
    final shouldForceUpdate =
        UpdateService.instance.shouldForceUpdate(widget.latestVersionInfo);
    return WillPopScope(
      onWillPop: () async => !shouldForceUpdate,
      child: AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 24,
              color: getEnteColorScheme(context).strokeMuted,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              shouldForceUpdate
                  ? context.l10n.criticalUpdateAvailable
                  : context.l10n.updateAvailable,
              style: enteTextTheme.h3Bold,
            ),
          ],
        ),
        content: content,
      ),
    );
  }
}

class ApkDownloaderDialog extends StatefulWidget {
  final LatestVersionInfo? versionInfo;

  const ApkDownloaderDialog(this.versionInfo, {Key? key}) : super(key: key);

  @override
  State<ApkDownloaderDialog> createState() => _ApkDownloaderDialogState();
}

class _ApkDownloaderDialogState extends State<ApkDownloaderDialog> {
  String? _saveUrl;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _saveUrl = Configuration.instance.getTempDirectory() +
        "ente-" +
        widget.versionInfo!.name! +
        ".apk";
    _downloadApk();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: const Text(
          "Downloading...",
          style: TextStyle(
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        content: LinearProgressIndicator(
          value: _downloadProgress,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.alternativeColor,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadApk() async {
    try {
      if (!File(_saveUrl!).existsSync()) {
        await Network.instance.getDio().download(
          widget.versionInfo!.url!,
          _saveUrl,
          onReceiveProgress: (count, _) {
            setState(() {
              _downloadProgress = count / widget.versionInfo!.size!;
            });
          },
        );
      }
      Navigator.of(context, rootNavigator: true).pop('dialog');
      // ignore: unawaited_futures
      OpenFilex.open(_saveUrl);
    } catch (e) {
      Logger("ApkDownloader").severe(e);
      final AlertDialog alert = AlertDialog(
        title: const Text("Sorry"),
        content: const Text("The download could not be completed"),
        actions: [
          TextButton(
            child: const Text(
              "Ignore",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop('dialog');
              Navigator.of(context, rootNavigator: true).pop('dialog');
            },
          ),
          TextButton(
            child: Text(
              "Retry",
              style: TextStyle(
                color: Theme.of(context).colorScheme.alternativeColor,
              ),
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop('dialog');
              Navigator.of(context, rootNavigator: true).pop('dialog');
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ApkDownloaderDialog(widget.versionInfo);
                },
                barrierDismissible: false,
              );
            },
          ),
        ],
      );
      // ignore: unawaited_futures
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
        barrierColor: Colors.black87,
      );
      return;
    }
  }
}
