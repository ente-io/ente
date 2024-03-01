class TrashRequest {
  final int fileID;
  final int collectionID;

  TrashRequest(this.fileID, this.collectionID);

  factory TrashRequest.fromJson(Map<String, dynamic> json) {
    return TrashRequest(json['fileID'], json['collectionID']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fileID'] = fileID;
    data['collectionID'] = collectionID;
    return data;
  }

  @override
  String toString() {
    return 'TrashItemRequest{fileID: $fileID, collectionID: $collectionID}';
  }
}
