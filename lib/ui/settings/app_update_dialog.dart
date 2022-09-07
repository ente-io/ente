// @dart=2.9

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:open_file/open_file.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/update_service.dart';

class AppUpdateDialog extends StatefulWidget {
  final LatestVersionInfo latestVersionInfo;

  const AppUpdateDialog(this.latestVersionInfo, {Key key}) : super(key: key);

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> changelog = [];
    for (final log in widget.latestVersionInfo.changelog) {
      changelog.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
          child: Text("- " + log, style: Theme.of(context).textTheme.caption),
        ),
      );
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.latestVersionInfo.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Padding(padding: EdgeInsets.all(8)),
        const Text(
          "Changelog",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        const Padding(padding: EdgeInsets.all(4)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: changelog,
        ),
        const Padding(padding: EdgeInsets.all(8)),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: OutlinedButton(
            style: Theme.of(context).outlinedButtonTheme.style.copyWith(
              textStyle: MaterialStateProperty.resolveWith<TextStyle>(
                (Set<MaterialState> states) {
                  return Theme.of(context).textTheme.subtitle1;
                },
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ApkDownloaderDialog(widget.latestVersionInfo);
                },
                barrierDismissible: false,
              );
            },
            child: const Text(
              "Update",
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
        title: Text(
          shouldForceUpdate ? "Critical update available" : "Update available",
        ),
        content: content,
      ),
    );
  }
}

class ApkDownloaderDialog extends StatefulWidget {
  final LatestVersionInfo versionInfo;

  const ApkDownloaderDialog(this.versionInfo, {Key key}) : super(key: key);

  @override
  State<ApkDownloaderDialog> createState() => _ApkDownloaderDialogState();
}

class _ApkDownloaderDialogState extends State<ApkDownloaderDialog> {
  String _saveUrl;
  double _downloadProgress;

  @override
  void initState() {
    super.initState();
    _saveUrl = Configuration.instance.getTempDirectory() +
        "ente-" +
        widget.versionInfo.name +
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
            Theme.of(context).colorScheme.greenAlternative,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadApk() async {
    try {
      await Network.instance.getDio().download(
        widget.versionInfo.url,
        _saveUrl,
        onReceiveProgress: (count, _) {
          setState(() {
            _downloadProgress = count / widget.versionInfo.size;
          });
        },
      );
      Navigator.of(context, rootNavigator: true).pop('dialog');
      OpenFile.open(_saveUrl);
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
                color: Theme.of(context).colorScheme.greenAlternative,
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
