import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/common_elements.dart';

class GrantPermissionsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            "assets/gallery.png",
            height: 160,
          ),
          Padding(padding: EdgeInsets.all(24)),
          Text.rich(
            TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: "ente",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: " needs your permission",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          Padding(padding: EdgeInsets.all(2)),
          Text(
            "to access your gallery",
            style: TextStyle(fontSize: 16),
          ),
          Padding(padding: const EdgeInsets.all(24)),
          Container(
            width: double.infinity,
            height: 64,
            padding: const EdgeInsets.fromLTRB(64, 0, 64, 0),
            child: button(
              "grant permission",
              fontSize: 16,
              onPressed: () async {
                final granted = await PhotoManager.requestPermission();
                if (granted) {
                  await SyncService.instance.onPermissionGranted();
                }
              },
            ),
          ),
          Padding(padding: const EdgeInsets.all(50)),
          Text(
            "we value your privacy",
            style: TextStyle(
              color: Colors.white30,
            ),
          ),
          Padding(padding: const EdgeInsets.all(12)),
          Text(
            "all the files you back up will be",
            style: TextStyle(
              color: Colors.white30,
            ),
          ),
          Padding(padding: const EdgeInsets.all(2)),
          Text(
            "end-to-end encrypted",
            style: TextStyle(
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }
}
