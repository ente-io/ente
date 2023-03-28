import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/ignored_files_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/text_input_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/location/radius_picker_widget.dart";

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final editNotifier = ValueNotifier(false);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 102),
        child: TitleBarWidget(
          isSliver: false,
          isFlexibleSpaceDisabled: false,
          flexibleSpaceTitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder(
                valueListenable: editNotifier,
                builder: (context, value, _) {
                  Widget child;
                  if (value as bool) {
                    child = SizedBox(
                      key: ValueKey(value),
                      width: double.infinity,
                      child: const TitleBarTitleWidget(
                        title: "Edit location",
                      ),
                    );
                  } else {
                    child = SizedBox(
                      key: ValueKey(value),
                      width: double.infinity,
                      child: const TitleBarTitleWidget(
                        title: "Location name",
                      ),
                    );
                  }
                  return AnimatedSwitcher(
                    switchInCurve: Curves.easeInExpo,
                    switchOutCurve: Curves.easeOutExpo,
                    duration: const Duration(milliseconds: 200),
                    child: child,
                  );
                },
              ),
              Text(
                "51 memories",
                style: getEnteTextTheme(context).smallMuted,
              ),
            ],
          ),
          actionIcons: [
            IconButton(
              onPressed: () {
                editNotifier.value = !editNotifier.value;
              },
              icon: const Icon(Icons.edit_rounded),
            )
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          ValueListenableBuilder(
            valueListenable: editNotifier,
            builder: (context, value, _) {
              return AnimatedCrossFade(
                firstCurve: Curves.easeInOutExpo,
                secondCurve: Curves.easeInOutExpo,
                sizeCurve: Curves.easeInOutExpo,
                firstChild: const LocationEditingWidget(),
                secondChild: const SizedBox(width: double.infinity),
                crossFadeState: editNotifier.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 300),
              );
            },
          ),
          const SizedBox(
              height: 1500, width: 320, child: LocationGalleryWidget()),
        ],
      ),
    );
  }
}

class LocationEditingWidget extends StatelessWidget {
  const LocationEditingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndexNotifier = ValueNotifier(defaultRadiusValueIndex);
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TextInputWidget(borderRadius: 2),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                color: Colors.amber,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4.5, 16, 4.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Center point",
                        style: textTheme.body,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Coordinates",
                        style: textTheme.miniMuted,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                color: getEnteColorScheme(context).strokeMuted,
              ),
            ],
          ),
          const SizedBox(height: 20),
          RadiusPickerWidget(selectedIndexNotifier),
        ],
      ),
    );
  }
}

class LocationGalleryWidget extends StatelessWidget {
  const LocationGalleryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        final ownerID = Configuration.instance.getUserID();
        final hasSelectedAllForBackup =
            Configuration.instance.hasSelectedAllFoldersForBackup();
        final collectionsToHide =
            CollectionsService.instance.collectionsHiddenFromTimeline();
        FileLoadResult result;
        if (hasSelectedAllForBackup) {
          result = await FilesDB.instance.getAllLocalAndUploadedFiles(
            creationStartTime,
            creationEndTime,
            ownerID!,
            limit: limit,
            asc: asc,
            ignoredCollectionIDs: collectionsToHide,
          );
        } else {
          result = await FilesDB.instance.getAllPendingOrUploadedFiles(
            creationStartTime,
            creationEndTime,
            ownerID!,
            limit: limit,
            asc: asc,
            ignoredCollectionIDs: collectionsToHide,
          );
        }

        // hide ignored files from home page UI
        final ignoredIDs = await IgnoredFilesService.instance.ignoredIDs;
        result.files.removeWhere(
          (f) =>
              f.uploadedFileID == null &&
              IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, f),
        );
        return result;
      },
      tagPrefix: "location_gallery",
    );
  }
}
