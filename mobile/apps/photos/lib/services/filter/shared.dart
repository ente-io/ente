import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/filter/filter.dart";

class SkipSharedFileFilter extends Filter {
  @override
  bool filter(EnteFile file) {
    return file.uploaderName == null && file.isOwner;
  }
}
