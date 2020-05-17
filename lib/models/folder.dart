class Folder {
  final int folderID;
  final String name;
  final String owner;
  final String deviceFolder;
  final List<String> sharedWith;
  final int updateTimestamp;

  Folder(
    this.folderID,
    this.name,
    this.owner,
    this.deviceFolder,
    this.sharedWith,
    this.updateTimestamp,
  );

  static Folder fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Folder(
      map['folderID'],
      map['name'],
      map['owner'],
      map['deviceFolder'],
      List<String>.from(map['sharedWith']),
      map['updateTimestamp'],
    );
  }

  @override
  String toString() {
    return 'Folder(folderID: $folderID, name: $name, owner: $owner, deviceFolder: $deviceFolder, sharedWith: $sharedWith, updateTimestamp: $updateTimestamp)';
  }
}
