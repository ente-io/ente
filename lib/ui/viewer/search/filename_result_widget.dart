import 'package:flutter/widgets.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';

class FileSuggestionsWigetGenerator extends StatelessWidget {
  final File matchedFile;
  const FileSuggestionsWigetGenerator(this.matchedFile, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    matchedFile.title,
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text('1 memory')
                ],
              ),
            ),
            SizedBox(
              height: 50,
              width: 50,
              child: ThumbnailWidget(matchedFile),
            ),
          ],
        ),
      ),
    );
  }
}
