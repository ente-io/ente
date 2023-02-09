import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/models/file.dart";
import "package:photos/services/object_detection/object_detection_service.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/utils/thumbnail_util.dart";

class ObjectTagsWidget extends StatelessWidget {
  final File file;

  const ObjectTagsWidget(this.file, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getThumbnail(file).then((data) {
        return ObjectDetectionService.instance.predict(data!);
      }),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<String> tags = snapshot.data!;
          if (tags.isEmpty) {
            return const ObjectTagWidget("No Results");
          }
          return ListView.builder(
            itemCount: tags.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return ObjectTagWidget(tags[index]);
            },
          );
        } else if (snapshot.hasError) {
          Logger("ObjectTagsWidget").severe(snapshot.error);
          return const Icon(Icons.error);
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }
}

class ObjectTagWidget extends StatelessWidget {
  final String name;
  const ObjectTagWidget(this.name, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: 10,
        bottom: 18,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .inverseBackgroundColor
            .withOpacity(0.025),
        borderRadius: const BorderRadius.all(
          Radius.circular(8),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            name!,
            style: Theme.of(context).textTheme.subtitle2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
