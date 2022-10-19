import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_result.dart';

class GenericSearchResult extends SearchResult {
  final String _name;
  final List<File> _files;
  final ResultType _type;

  GenericSearchResult(this._type, this._name, this._files);

  @override
  String name() {
    return _name;
  }

  @override
  ResultType type() {
    return _type;
  }

  @override
  File? previewThumbnail() {
    return _files.first;
  }

  @override
  List<File> resultFiles() {
    return _files;
  }
}
