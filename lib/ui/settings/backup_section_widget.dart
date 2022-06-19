import 'dart:io';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/backup_status.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/services/deduplication_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/backup_folder_selection_page.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/deduplicate_page.dart';
import 'package:photos/ui/free_space_page.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

class BackupSectionWidget extends StatefulWidget {
  BackupSectionWidget({Key key}) : super(key: key);

  @override
  BackupSectionWidgetState createState() => BackupSectionWidgetState();
}

class BackupSectionWidgetState extends State<BackupSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: SettingsSectionTitle("Backup"),
      collapsed: Container(),
      expanded: _getSectionOptions(context),
      theme: getExpandableTheme(context),
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final List<Widget> sectionOptions = [
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          routeToPage(
            context,
            BackupFolderSelectionPage(
              buttonText: "Backup",
            ),
          );
        },
        child: SettingsTextItem(
          text: "Backed up folders",
          icon: Icons.navigate_next,
        ),
      ),
      SectionOptionDivider,
      SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Backup over mobile data",
              style: Theme.of(context).textTheme.subtitle1,
            ),
            Switch.adaptive(
              value: Configuration.instance.shouldBackupOverMobileData(),
              onChanged: (value) async {
                Configuration.instance.setBackupOverMobileData(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
      SectionOptionDivider,
      SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Backup videos",
              style: Theme.of(context).textTheme.subtitle1,
            ),
            Switch.adaptive(
              value: Configuration.instance.shouldBackupVideos(),
              onChanged: (value) async {
                Configuration.instance.setShouldBackupVideos(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    ];
    if (Platform.isIOS) {
      sectionOptions.addAll([
        SectionOptionDivider,
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Keep device awake",
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Switch.adaptive(
                value: Configuration.instance.shouldKeepDeviceAwake(),
                onChanged: (value) async {
                  if (value) {
                    var choice = await showChoiceDialog(
                      context,
                      "Keep device awake?",
                      "This will ensure faster uploads by keeping your display on while uploads are in progress.",
                      firstAction: "No",
                      secondAction: "Yes",
                    );
                    if (choice != DialogUserChoice.secondChoice) {
                      return;
                    }
                  }
                  await Configuration.instance.setShouldKeepDeviceAwake(value);
                  showShortToast(
                    context,
                    value
                        ? "Device will stay awake during uploads"
                        : "Device will not stay awake during uploads",
                  );
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ]);
    }
    sectionOptions.addAll(
      [
        SectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            final dialog = createProgressDialog(context, "Calculating...");
            await dialog.show();
            BackupStatus status;
            try {
              status = await SyncService.instance.getBackupStatus();
            } catch (e, s) {
              await dialog.hide();
              showGenericErrorDialog(context);
              return;
            }

            await dialog.hide();
            if (status.localIDs.isEmpty) {
              showErrorDialog(
                context,
                "✨ All clear",
                "You've no files on this device that can be deleted",
              );
            } else {
              bool result = await routeToPage(context, FreeSpacePage(status));
              if (result == true) {
                _showSpaceFreedDialog(status);
              }
            }
          },
          child: SettingsTextItem(
            text: "Free up space",
            icon: Icons.navigate_next,
          ),
        ),
        SectionOptionDivider,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            final dialog = createProgressDialog(context, "Calculating...");
            await dialog.show();
            List<DuplicateFiles> duplicates;
            try {
              duplicates =
                  await DeduplicationService.instance.getDuplicateFiles();
            } catch (e) {
              await dialog.hide();
              showGenericErrorDialog(context);
              return;
            }

            await dialog.hide();
            if (duplicates.isEmpty) {
              showErrorDialog(
                context,
                "✨ No duplicates",
                "You've no duplicate files that can be cleared",
              );
            } else {
              DeduplicationResult result =
                  await routeToPage(context, DeduplicatePage(duplicates));
              if (result != null) {
                _showDuplicateFilesDeletedDialog(result);
              }
            }
          },
          child: SettingsTextItem(
            text: "Deduplicate files",
            icon: Icons.navigate_next,
          ),
        ),
      ],
    );
    return Column(
      children: sectionOptions,
    );
  }

  void _showSpaceFreedDialog(BackupStatus status) {
    AlertDialog alert = AlertDialog(
      title: Text("Success"),
      content: Text(
        "You have successfully freed up " + formatBytes(status.size) + "!",
      ),
      actions: [
        TextButton(
          child: Text(
            "Rate us",
            style: TextStyle(
              color: Theme.of(context).buttonColor,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            // TODO: Replace with https://pub.dev/packages/in_app_review
            if (Platform.isAndroid) {
              launch(
                "https://play.google.com/store/apps/details?id=io.ente.photos",
              );
            } else {
              launch("https://apps.apple.com/in/app/ente-photos/id1542026904");
            }
          },
        ),
        TextButton(
          child: Text(
            "Ok",
          ),
          onPressed: () {
            if (Platform.isIOS) {
              showToast(
                context,
                "Also empty \"Recently Deleted\" from \"Settings\" -> \"Storage\" to claim the freed space",
              );
            }
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );
    showConfettiDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
      barrierColor: Colors.black87,
      confettiAlignment: Alignment.topCenter,
      useRootNavigator: true,
    );
  }

  void _showDuplicateFilesDeletedDialog(DeduplicationResult result) {
    String countText = result.count.toString() +
        " duplicate file" +
        (result.count == 1 ? "" : "s");
    AlertDialog alert = AlertDialog(
      title: Text("✨ Success"),
      content: Text(
        "You have cleaned up " +
            countText +
            ", saving " +
            formatBytes(result.size) +
            "!",
      ),
      actions: [
        TextButton(
          child: Text(
            "Rate us",
            style: TextStyle(
              color: Theme.of(context).buttonColor,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            // TODO: Replace with https://pub.dev/packages/in_app_review
            if (Platform.isAndroid) {
              launch(
                "https://play.google.com/store/apps/details?id=io.ente.photos",
              );
            } else {
              launch("https://apps.apple.com/in/app/ente-photos/id1542026904");
            }
          },
        ),
        TextButton(
          child: Text(
            "Ok",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: () {
            showToast(
              context,
              "Also empty your \"Trash\" to claim the freed up space",
            );
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );
    showConfettiDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
      barrierColor: Colors.black87,
      confettiAlignment: Alignment.topCenter,
      useRootNavigator: true,
    );
  }
}
