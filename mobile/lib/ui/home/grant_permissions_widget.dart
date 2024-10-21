import "dart:async";
import 'dart:io';

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photo_manager/photo_manager.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/sync_service.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/photo_manager_util.dart";
import "package:styled_text/styled_text.dart";

class GrantPermissionsWidget extends StatefulWidget {
  const GrantPermissionsWidget({super.key});

  @override
  State<GrantPermissionsWidget> createState() => _GrantPermissionsWidgetState();
}

class _GrantPermissionsWidgetState extends State<GrantPermissionsWidget> {
  final Logger _logger = Logger("_GrantPermissionsWidgetState");

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 120),
          child: Column(
            children: [
              const SizedBox(
                height: 24,
              ),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    isLightMode
                        ? Image.asset(
                            'assets/loading_photos_background.png',
                            color: Colors.white.withOpacity(0.4),
                            colorBlendMode: BlendMode.modulate,
                          )
                        : Image.asset(
                            'assets/loading_photos_background_dark.png',
                          ),
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 42),
                          Image.asset(
                            "assets/gallery_locked.png",
                            height: 160,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                child: StyledText(
                  text: S.of(context).entePhotosPerm,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontWeight: FontWeight.w700),
                  tags: {
                    'i': StyledTextTag(
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.w400),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: getEnteColorScheme(context).backgroundBase,
              spreadRadius: 190,
              blurRadius: 30,
              offset: const Offset(0, 170),
            ),
          ],
        ),
        width: double.infinity,
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 16,
        ),
        child: OutlinedButton(
          key: const ValueKey("grantPermissionButton"),
          child: Text(S.of(context).grantPermission),
          onPressed: () async {
            try {
              final state = await requestPhotoMangerPermissions();
              _logger.info("Permission state: $state");
              if (state == PermissionState.authorized ||
                  state == PermissionState.limited) {
                await SyncService.instance.onPermissionGranted(state);
              } else if (state == PermissionState.denied) {
                final AlertDialog alert = AlertDialog(
                  title: Text(S.of(context).pleaseGrantPermissions),
                  content: Text(
                    S.of(context).enteCanEncryptAndPreserveFilesOnlyIfYouGrant,
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        S.of(context).ok,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop('dialog');
                        if (Platform.isIOS) {
                          PhotoManager.openSetting();
                        }
                      },
                    ),
                  ],
                );
                // ignore: unawaited_futures
                showDialog(
                  useRootNavigator: false,
                  context: context,
                  builder: (BuildContext context) {
                    return alert;
                  },
                  barrierColor: Colors.black12,
                );
              } else {
                throw Exception("Unknown permission state: $state");
              }
            } catch (e) {
              _logger.severe(
                "Failed to request permission: ${e.toString()}",
                e,
              );
              showGenericErrorDialog(context: context, error: e).ignore();
            }
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
