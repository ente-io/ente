import "package:flutter/cupertino.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/search/search_result.dart';
import "package:photos/models/search/search_types.dart";

class GenericSearchResult extends SearchResult {
  final String _name;
  final List<EnteFile> _files;
  final ResultType _type;
  final Function(BuildContext context)? onResultTap;
  final Map<String, dynamic> params;

  GenericSearchResult(
    this._type,
    this._name,
    this._files, {
    this.onResultTap,
    this.params = const {},
  });

  @override
  String name() {
    return _name;
  }

  @override
  ResultType type() {
    return _type;
  }

  @override
  EnteFile? previewThumbnail() {
    return _files.first;
  }

  @override
  List<EnteFile> resultFiles() {
    return _files;
  }
}
