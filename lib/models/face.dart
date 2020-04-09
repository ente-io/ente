class Face {
  final int faceID;
  final String thumbnailPath;

  Face.fromJson(Map<String, dynamic> json)
      : faceID = json["faceID"],
        thumbnailPath = json["thumbnailPath"];
}
