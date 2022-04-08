import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/sync_service.dart';

class GrantPermissionsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                'ente needs your permission to access gallery',
                style:
                    Theme.of(context).textTheme.headline4.copyWith(height: 1.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Divider(
                thickness: 1.5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Why we need permissions',
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    width: 40,
                    color: Colors.greenAccent,
                  ),
                ),
                title: Text("hey there random stuff"),
                subtitle: Text(
                    "Even more random stuff here. blah blabh blahhasdn asidf as"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 180),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    width: 40,
                    color: Colors.greenAccent,
                  ),
                ),
                title: Text("hey there random stuff"),
                subtitle: Text(
                    "Even more random stuff here. blah blabh blahhasdn asidf as"),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
            color: Theme.of(context).backgroundColor,
            spreadRadius: 200,
            blurRadius: 100,
            offset: Offset(0, 150),
          )
        ]),
        width: double.infinity,
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: FloatingActionButton.extended(
            backgroundColor: Theme.of(context).colorScheme.fabBackgroundColor,
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
            label: Text('Grant permission',
                style: Theme.of(context).textTheme.headline6.copyWith(
                    color: Theme.of(context).colorScheme.fabTextOrIconColor)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
