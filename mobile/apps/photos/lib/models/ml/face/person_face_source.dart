import 'package:photos/models/file/file.dart';
import 'package:photos/models/ml/face/face.dart';

class PersonFaceSource {
  final EnteFile file;
  final Face face;
  final int resolvedFileId;
  final String? personName;

  const PersonFaceSource({
    required this.file,
    required this.face,
    required this.resolvedFileId,
    this.personName,
  });
}
