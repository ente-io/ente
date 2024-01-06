import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
// import 'package:open_file/open_file.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/update_service.dart';
import 'package:photos/theme/ente_theme.dart';
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
    final List<Widget> changelog = [];
    final enteTextTheme = getEnteTextTheme(context);
    final enteColor = getEnteColorScheme(context);
    for (final log in widget.latestVersionInfo!.changelog) {
      changelog.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "- ",
                style: enteTextTheme.small.copyWith(color: enteColor.textMuted),
              ),
              Flexible(
                child: Text(
                  log,
                  softWrap: true,
                  style:
                      enteTextTheme.small.copyWith(color: enteColor.textMuted),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.of(context).aNewVersionOfEnteIsAvailable,
          style: enteTextTheme.body.copyWith(color: enteColor.textMuted),
        ),
        const Padding(padding: EdgeInsets.all(8)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: changelog,
        ),
        const Padding(padding: EdgeInsets.all(8)),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            style: Theme.of(context).outlinedButtonTheme.style!.copyWith(
              textStyle: MaterialStateProperty.resolveWith<TextStyle>(
                (Set<MaterialState> states) {
                  return enteTextTheme.bodyBold;
                },
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              // ignore: unawaited_futures
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ApkDownloaderDialog(widget.latestVersionInfo);
                },
                barrierDismissible: false,
              );
            },
            child: Text(
              S.of(context).update,
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(8)),
        Center(
          child: InkWell(
            child: Text(
              S.of(context).installManually,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(decoration: TextDecoration.underline),
            ),
            onTap: () => launchUrlString(
              widget.latestVersionInfo!.url,
              mode: LaunchMode.externalApplication,
            ),
          ),
        ),
      ],
    );
    final shouldForceUpdate =
        UpdateService.instance.shouldForceUpdate(widget.latestVersionInfo!);
    return WillPopScope(
      onWillPop: () async => !shouldForceUpdate,
      child: AlertDialog(
        key: const ValueKey("updateAppDialog"),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: enteColor.strokeMuted,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              shouldForceUpdate
                  ? S.of(context).criticalUpdateAvailable
                  : S.of(context).updateAvailable,
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
        widget.versionInfo!.name +
        ".apk";
    _downloadApk();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: Text(
          S.of(context).downloading,
          style: const TextStyle(
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
      await NetworkClient.instance.getDio().download(
        widget.versionInfo!.url,
        _saveUrl,
        onReceiveProgress: (count, _) {
          setState(() {
            _downloadProgress = count / widget.versionInfo!.size;
          });
        },
      );
      Navigator.of(context, rootNavigator: true).pop('dialog');
      // OpenFile.open(_saveUrl);
    } catch (e) {
      Logger("ApkDownloader").severe(e);
      final AlertDialog alert = AlertDialog(
        title: Text(S.of(context).sorry),
        content: Text(S.of(context).theDownloadCouldNotBeCompleted),
        actions: [
          TextButton(
            child: Text(
              S.of(context).ignoreUpdate,
              style: const TextStyle(
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
              S.of(context).retry,
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
