class Photo {
  String photoID;
  String url;
  String localPath;
  String hash;
  int syncTimestamp;

  Photo.fromJson(Map<String, dynamic> json)
      : photoID = json["photoID"],
        url = json["url"],
        syncTimestamp = json["syncTimestamp"];

  Photo.fromRow(Map<String, dynamic> row)
      : photoID = row["photo_id"],
        localPath = row["local_path"],
        url = row["url"],
        hash = row["hash"],
        syncTimestamp = int.parse(row["sync_timestamp"]);
}
