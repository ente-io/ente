import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
// import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/sync_service.dart';

class GrantPermissionsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Image.asset(
                    "assets/gallery.png",
                    height: 250,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Ente needs your permission to access gallery',
                  style: Theme.of(context)
                      .textTheme
                      .headline4
                      .copyWith(height: 1.4),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
                left: 20, right: 20, bottom: Platform.isIOS ? 60 : 32),
            child: OutlinedButton(
              child: Text("Grant permission"),
              onPressed: () async {
                final state = await PhotoManager.requestPermissionExtend();
                if (state == PermissionState.authorized ||
                    state == PermissionState.limited) {
                  await SyncService.instance.onPermissionGranted(state);
                } else if (state == PermissionState.denied) {
                  AlertDialog alert = AlertDialog(
                    title: Text("Please grant permissions"),
                    content: Text(
                        "ente can encrypt and preserve files only if you grant access to them"),
                    actions: [
                      TextButton(
                        child: Text(
                          "OK",
                          style: Theme.of(context).textTheme.subtitle1.copyWith(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true)
                              .pop('dialog');
                          if (Platform.isIOS) {
                            PhotoManager.openSetting();
                          }
                        },
                      ),
                    ],
                  );

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: alert,
                      );
                    },
                    barrierColor: Colors.black12,
                  );
                }
              },
              // padding: EdgeInsets.fromLTRB(12, 20, 12, 20),
            ),
          ),
        ],
      ),
    );
  }
}
