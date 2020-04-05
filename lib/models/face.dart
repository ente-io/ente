class Face {
  final int faceID;
  final String thumbnailURL;

  Face.fromJson(Map<String, dynamic> json)
      : faceID = json["faceID"],
        thumbnailURL = json["thumbnailURL"];
}
