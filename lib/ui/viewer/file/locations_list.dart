import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:photos/db/files_db.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/services/location_service.dart";
import "package:photos/ui/viewer/file/location_detail.dart";

//state = 0; normal mode
//state = 1; selection mode
class LocationsList extends StatelessWidget {
  final int state;
  final int? fileId;
  LocationsList({super.key, this.state = 0, this.fileId});

  final clusteredLocationList =
      LocationService.instance.clusterFilesByLocation();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 0, 0),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(text: "Locations"),
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 0, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(text: clusteredLocationList.length.toString()),
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...clusteredLocationList.entries.map((entry) {
              final location = json.decode(entry.key);
              return InkWell(
                onTap: () async {
                  if (state == 1) {
                    await LocationService.instance
                        .addFileToLocation(location["id"], fileId!);
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: ListTile(
                    horizontalTitleGap: 2,
                    title: Text(
                      location["name"],
                    ),
                    subtitle: Text(
                      "${entry.value.length} memories",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .defaultTextColor
                                .withOpacity(0.5),
                          ),
                    ),
                    trailing: state == 0
                        ? IconButton(
                            onPressed: () async {},
                            icon: const Icon(Icons.arrow_forward_ios),
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
            InkWell(
              onTap: () {
                unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const CreateLocation();
                      },
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: const ListTile(
                  horizontalTitleGap: 2,
                  leading: Icon(Icons.add_location_alt_rounded),
                  title: Text(
                    "Add New",
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LocationFilesList extends StatelessWidget {
  final List<String> fileIDs;
  const LocationFilesList({super.key, required this.fileIDs});

  Future<void> generateFiles() async {
    final files = List.empty(growable: true);
    for (String fileID in fileIDs) {
      final file = await (FilesDB.instance.getFile(int.parse(fileID)));
      files.add(file!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ...LocationService.instance
                .clusterFilesByLocation()
                .entries
                .map(
                  (entry) => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: ListTile(
                      horizontalTitleGap: 2,
                      title: Text(
                        entry.key,
                      ),
                      subtitle: Text(
                        "${entry.value.length} memories",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .defaultTextColor
                                  .withOpacity(0.5),
                            ),
                      ),
                      trailing: IconButton(
                        onPressed: () async {},
                        icon: const Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  ),
                )
                .toList(),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: const ListTile(
                horizontalTitleGap: 2,
                leading: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.add_location_alt_rounded),
                ),
                title: Text(
                  "Add Location",
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
