import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";

class ClusterBreakupPage extends StatefulWidget {
  final Map<int, List<EnteFile>> newClusterIDsToFiles;
  final String title;

  const ClusterBreakupPage(
    this.newClusterIDsToFiles,
    this.title, {
    super.key,
  });

  @override
  State<ClusterBreakupPage> createState() => _ClusterBreakupPageState();
}

class _ClusterBreakupPageState extends State<ClusterBreakupPage> {
  @override
  Widget build(BuildContext context) {
    final keys = widget.newClusterIDsToFiles.keys.toList();
    final clusterIDsToFiles = widget.newClusterIDsToFiles;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: widget.newClusterIDsToFiles.keys.length,
        itemBuilder: (context, index) {
          final int clusterID = keys[index];
          final List<EnteFile> files = clusterIDsToFiles[keys[index]]!;
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ClusterPage(
                    files,
                    clusterID: index,
                    appendTitle: "(Analysis)",
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: files.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.elliptical(16, 12),
                            ),
                            child: PersonFaceWidget(
                              files.first,
                              clusterID: clusterID,
                            ),
                          )
                        : const ClipRRect(
                            borderRadius:
                                BorderRadius.all(Radius.elliptical(16, 12)),
                            child: NoThumbnailWidget(
                              addBorder: false,
                            ),
                          ),
                  ),
                  const SizedBox(
                    width: 8.0,
                  ), // Add some spacing between the thumbnail and the text
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            "${clusterIDsToFiles[keys[index]]!.length} photos",
                            style: getEnteTextTheme(context).body,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
