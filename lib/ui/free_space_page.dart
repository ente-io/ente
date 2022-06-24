import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/backup_status.dart';
import 'package:photos/ui/common/gradientButton.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/delete_file_util.dart';

class FreeSpacePage extends StatefulWidget {
  final BackupStatus status;

  FreeSpacePage(this.status, {Key key}) : super(key: key);

  @override
  _FreeSpacePageState createState() => _FreeSpacePageState();
}

class _FreeSpacePageState extends State<FreeSpacePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("Free up space"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    Logger("FreeSpacePage").info(
      "Number of uploaded files: " + widget.status.localIDs.length.toString(),
    );
    Logger("FreeSpacePage")
        .info("Space consumed: " + widget.status.size.toString());
    return SingleChildScrollView(
      child: _getWidget(widget.status),
    );
  }

  Widget _getWidget(BackupStatus status) {
    final count = status.localIDs.length;
    final formattedCount = NumberFormat().format(count);
    final informationTextStyle = TextStyle(
      fontSize: 14,
      height: 1.3,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
      fontWeight: FontWeight.w500,
    );
    final isLightMode =
        MediaQuery.of(context).platformBrightness == Brightness.light;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            isLightMode
                ? Image.asset(
                    'assets/loading_photos_background.png',
                    color: Colors.white.withOpacity(0.4),
                    colorBlendMode: BlendMode.modulate,
                  )
                : Image.asset('assets/loading_photos_background_dark.png'),
            Image.asset(
              "assets/backed_up_gallery.png",
              height: 160,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 36, right: 40),
          child: Row(
            children: [
              Icon(
                Icons.cloud_done_outlined,
                color: Color.fromRGBO(45, 194, 98, 1.0),
              ),
              Padding(padding: EdgeInsets.all(10)),
              Expanded(
                child: Text(
                  count == 1
                      ? formattedCount.toString() +
                          " file on this device has been backed up safely"
                      : formattedCount.toString() +
                          " files on this device have been backed up safely",
                  style: informationTextStyle,
                ),
              ),
            ],
          ),
        ),
        Padding(padding: EdgeInsets.all(12)),
        Padding(
          padding: const EdgeInsets.only(left: 36, right: 40),
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Color.fromRGBO(45, 194, 98, 1.0),
              ),
              Padding(padding: EdgeInsets.all(10)),
              Expanded(
                child: Text(
                  (count == 1 ? "It" : "They") +
                      " can be deleted from this device to free up " +
                      formatBytes(status.size),
                  style: informationTextStyle,
                ),
              ),
            ],
          ),
        ),
        Padding(padding: EdgeInsets.all(12)),
        Padding(
          padding: const EdgeInsets.only(left: 36, right: 40),
          child: Row(
            children: [
              Icon(
                Icons.devices,
                color: Color.fromRGBO(45, 194, 98, 1.0),
              ),
              Padding(padding: EdgeInsets.all(10)),
              Expanded(
                child: Text(
                  "You can still access " +
                      (count == 1 ? "it" : "them") +
                      " on ente as long as you have an active subscription",
                  style: informationTextStyle,
                ),
              ),
            ],
          ),
        ),
        Padding(padding: EdgeInsets.all(24)),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 64,
          ),
          padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
          child: GradientButton(
            child: Text(
              "Free up " + formatBytes(status.size),
              style: gradientButtonTextTheme(),
            ),
            linearGradientColors: const [
              Color(0xFF2CD267),
              Color(0xFF1DB954),
            ],
            onTap: () async {
              await _freeStorage(status);
            },
          ),
        ),
        Padding(padding: EdgeInsets.all(24)),
      ],
    );
  }

  Future<void> _freeStorage(BackupStatus status) async {
    final result = await deleteLocalFiles(context, status.localIDs);
    if (result) {
      Navigator.of(context).pop(true);
    }
  }
}
