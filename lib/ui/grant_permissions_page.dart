import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/loading_photos_page.dart';

class GrantPermissionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              "ente needs your permission to display your gallery",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 64,
            padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
            child: RaisedButton(
              child: Text(
                "grant permission",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              onPressed: () async {
                final granted = await PhotoManager.requestPermission();
                if (granted) {
                  await SyncService.instance.onPermissionGranted();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return LoadingPhotosPage();
                      },
                    ),
                  );
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
