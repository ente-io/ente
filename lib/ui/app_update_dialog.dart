import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:open_file/open_file.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/common_elements.dart';

class AppUpdateDialog extends StatefulWidget {
  final LatestVersionInfo latestVersionInfo;

  AppUpdateDialog(this.latestVersionInfo, {Key key}) : super(key: key);

  @override
  _AppUpdateDialogState createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> changelog = [];
    for (final log in widget.latestVersionInfo.changelog) {
      changelog.add(Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
        child: Text("- " + log,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            )),
      ));
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.latestVersionInfo.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Padding(padding: EdgeInsets.all(8)),
        Text("changelog",
            style: TextStyle(
              fontSize: 18,
            )),
        Padding(padding: EdgeInsets.all(4)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: changelog,
        ),
        Padding(padding: EdgeInsets.all(8)),
        Container(
          width: double.infinity,
          height: 64,
          padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
          child: button(
            "update",
            fontSize: 16,
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
          ),
        ),
      ],
    );
    final shouldForceUpdate =
        UpdateService.instance.shouldForceUpdate(widget.latestVersionInfo);
    return WillPopScope(
      onWillPop: () async => !shouldForceUpdate,
      child: AlertDialog(
        title: Text(shouldForceUpdate? "critical update available" : "update available"),
        content: content,
      ),
    );
  }
}

class ApkDownloaderDialog extends StatefulWidget {
  final LatestVersionInfo versionInfo;

  ApkDownloaderDialog(this.versionInfo, {Key key}) : super(key: key);

  @override
  _ApkDownloaderDialogState createState() => _ApkDownloaderDialogState();
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
        title: Text(
          "downloading...",
          style: TextStyle(
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        content: LinearProgressIndicator(
          value: _downloadProgress,
          valueColor:
              AlwaysStoppedAnimation<Color>(Theme.of(context).buttonColor),
        ),
      ),
    );
  }

  Future<void> _downloadApk() async {
    try {
      await Network.instance.getDio().download(widget.versionInfo.url, _saveUrl,
          onReceiveProgress: (count, _) {
        setState(() {
          _downloadProgress = count / widget.versionInfo.size;
        });
      });
      Navigator.of(context, rootNavigator: true).pop('dialog');
      OpenFile.open(_saveUrl);
    } catch (e) {
      Logger("ApkDownloader").severe(e);
      AlertDialog alert = AlertDialog(
        title: Text("sorry"),
        content: Text("the download could not be completed"),
        actions: [
          TextButton(
            child: Text(
              "ignore",
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
              "retry",
              style: TextStyle(
                color: Theme.of(context).buttonColor,
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
